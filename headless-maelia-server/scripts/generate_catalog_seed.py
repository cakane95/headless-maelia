"""Génère le seed du catalogue des entrées depuis le modèle GAML et les données réelles.

Deux sources, dans cet ordre d'autorité :
  1. le **code GAML** — quels fichiers sont lus, où, par quel module ;
  2. les **fichiers livrés** sous `includes/` — quels champs existent vraiment.

Le tableur `MAELIA_Schema_Donnees.xlsx` n'est PAS utilisé : l'analyse
(cf. docs/docs/reference/donnees-et-parametres.md §5.3) a montré qu'il contient des
erreurs de collecte et décrit la moitié de ses feuilles positionnellement.

Usage (depuis la racine du dépôt) :
    python headless-maelia-server/scripts/generate_catalog_seed.py
"""

from __future__ import annotations

import collections
import json
import pathlib
import re
import struct
import sys

RACINE = pathlib.Path(__file__).resolve().parents[2]
MODELE = RACINE / "gama-models" / "MAELIA_1.4.29_GAMA_2025-06"
MODELS, INCLUDES = MODELE / "models", MODELE / "includes"
SORTIE = (
    pathlib.Path(__file__).resolve().parents[1]
    / "app/contexts/catalog/infrastructure/seed/dataspecs.json"
)

PREFIXE_MODULE = {
    "modeleAgricole": "agri",
    "modeleCommun": "commun",
    "modeleHydrographique": "hydro",
    "modeleNormatif": "normatif",
}

# Familles a nom dynamique : le code compose le nom a l'execution.
# id -> (relative_dir, motif de reconnaissance, libelle)
# Familles a nom dynamique. Le quatrieme element dit si le modele s'arrete quand
# la famille est absente : il ne se deduit pas d'un nom de fichier litteral,
# puisqu'il n'y en a pas.
MULTI_INSTANCE = {
    "commun.meteo.observee": (
        "modeleCommun/meteo/observee",
        r"\d{4}\.csv",
        "Serie climatique observee (un fichier par annee)",
        # « aucun fichier meteo pour l'annee X » -> ERREUR LORS DE L'INITIALISATION
        True,
    ),
    "commun.meteo.simulee": (
        "modeleCommun/meteo/simulee",
        r"\d{4}\.csv",
        "Serie climatique simulee (scenario / annee)",
        # Lue seulement si nomScenarioClimatique est renseigne.
        False,
    ),
    "agri.marcheAgricole.prixVentes": (
        "modeleAgricole/marcheAgricole",
        r"prixVentes.+\.csv",
        "Prix de vente par scenario",
        # Un fichier par scenario de prix declare : sans scenario, rien a lire.
        False,
    ),
    "agri.blocs": (
        "modeleAgricole",
        r"blocs(?!.*_cor).+\.csv",
        "Blocs d'assolement (selon nomChoixAssolement)",
        # bloc.gaml:46 — absent, le modele construit les blocs lui-meme.
        False,
    ),
    "agri.blocsCorriges": (
        "modeleAgricole",
        r"blocs.+_cor\.csv",
        "Blocs d'assolement corriges",
        False,
    ),
    "hydro.canaux.donneesDetaillees": (
        "modeleHydrographique/canaux",
        r"(?!canaux\.csv).+\.csv",
        "Donnees detaillees par canal",
        # main.gaml:344 — lus seulement si le shapefile des canaux existe.
        False,
    ),
}

# Applicabilite : quel parametre rend le fichier necessaire (cf. inventaire 6.3).
REQUIRED_IF_MODULE = {
    "modeleHydrographique": "executerModeleHydrographique == true",
    "modeleNormatif": "executerModeleNormatif == true",
}
REQUIRED_IF_SPEC = {
    "hydro.zonesHydrographiques.donneesMNT_ZH": "nomChoixModeleHydrographique == 'SWAT'",
    "normatif.barrages.barrages": "executerBarrage == true",
    "agri.ilots.horsZone.ilots_HZ": "avecIlotsHorsZone == true",
    "agri.ilots.horsZone.parcelles_HZ": "avecIlotsHorsZone == true",
    "agri.culture.especesHerbSim": "nomChoixModeleCroissancePrairie == 'HerbSim'",
    "agri.agriculteurs.profilesAgriculteurs": "nomChoixAssolement == 'FonctionsDeCroyances'",
    "agri.agriculteurs.lotsAnimaux": "executerModeleElevage == true",
    "agri.agriculteurs.batiments": "executerModeleElevage == true",
    "commun.meteo.simulee": "nomScenarioClimatique != ''",
}

# Dependances "par construction" (cf. inventaire 6.4 et V16 de la version Java).
DEPENDS_ON = {
    "hydro.zonesHydrographiques.contourZH": ["hydro.zonesHydrographiques.ZH"],
    "hydro.zonesHydrographiques.donneesMNT_ZH": ["hydro.zonesHydrographiques.ZH"],
    "hydro.zonesHydrographiques.debitEntre": ["hydro.zonesHydrographiques.ZH"],
    "hydro.zonesHydrographiques.debitEntreObs": ["hydro.zonesHydrographiques.ZH"],
    "hydro.nappes.nappeParZH": ["hydro.zonesHydrographiques.ZH"],
    "hydro.retenuesCollinaires.retenuesParZH": ["hydro.zonesHydrographiques.ZH"],
    "hydro.clc.clcParZH": ["hydro.zonesHydrographiques.ZH"],
    "hydro.clc.clcRPGParZH": ["hydro.zonesHydrographiques.ZH"],
    "hydro.troncons.tronconsPrincipauxParZH": ["hydro.zonesHydrographiques.ZH"],
    "commun.typesDeSol.typeDeSolParZH": ["hydro.zonesHydrographiques.ZH"],
    "commun.altitude.altitudeAgregeesParZH": ["hydro.zonesHydrographiques.ZH"],
    "agri.ilots.dansZone.parcelles": ["agri.ilots.dansZone.ilots"],
    "agri.ilots.dansZone.ilots": [
        "hydro.zonesHydrographiques.ZH",
        "commun.typesDeSol.typeDeSolParZH",
        "agri.agriculteurs.exploitations",
    ],
    "agri.culture.reglesDeDecisions": ["agri.culture.especesCultivees"],
    "agri.culture.reglesDeDecisions_fertilisation": ["agri.culture.especesCultivees"],
    "agri.marcheAgricole.prixVentes": ["agri.culture.especesCultivees"],
    "commun.meteo.observee": ["commun.meteo.polygonesMeteoFrance"],
}

# Orientation des fichiers tabulaires — TABLE EXPLICITE, pas une heuristique.
#
# Une detection par la forme est trompeuse : reglesDeDecisions.csv fait 402 lignes
# pour 49 colonnes tout en etant transpose. L'equipe Java avait du corriger ces
# memes orientations a la main (migration V17). Une orientation doit etre JUSTE,
# pas probable : on l'inscrit ici apres inspection du fichier reel.
#
# id -> (orientation, matrix_value_start_index)
#   FIELDS_AS_ROWS = transpose : les noms de champs sont en colonne 0,
#   chaque colonne suivante decrit une entite.
#   matrix_value_start_index = premiere colonne de valeurs (1, ou 2 si le fichier
#   intercale une colonne meta entre le nom du champ et les valeurs).
ORIENTATIONS = {
    "agri.Engrais.Engrais": ("FIELDS_AS_ROWS", 1),
    "agri.culture.especesCultivees": ("FIELDS_AS_ROWS", 1),
    "agri.culture.especesHerbSim": ("FIELDS_AS_ROWS", 1),
    "agri.culture.reglesDeDecisions": ("FIELDS_AS_ROWS", 2),
    "agri.culture.reglesDeDecisions_fertilisation": ("FIELDS_AS_ROWS", 2),
}
DEFAUT_ORIENTATION = ("FIELDS_AS_COLUMNS", None)

# Chemins composes a l'execution, resolus a la main depuis le code.
DYNAMIQUES = {
    "modeleCommun/typesDeSol/typeDeSolParZH.shp": "modeleCommun/typeDeSol.gaml",
    "modeleAgricole/culture/reglesDeDecisions.csv":
        "modeleAgricole/SystemesDeCultures/systemeDeCultureDeReference.gaml",
    "modeleAgricole/culture/reglesDeDecisions_fertilisation.csv":
        "modeleAgricole/SystemesDeCultures/systemeDeCultureDeReference.gaml",
    "modeleNormatif/barrages/barrages.csv": "modeleNormatif/barrage.gaml",
    "modeleNormatif/zonesAdministratives/secteursAdministratifs.shp":
        "modeleNormatif/secteurAdministratif.gaml",
    "modeleNormatif/zonesAdministratives/joursRestrictionSecteurs.csv":
        "modeleNormatif/secteurAdministratif.gaml",
    "modeleNormatif/zonesAdministratives/zonesAdministratives.shp":
        "modeleNormatif/zoneAdministrative.gaml",
    "modeleNormatif/zonesAdministratives/seuilsDeRestriction.csv":
        "modeleNormatif/zoneAdministrativeSimple.gaml",
    "modeleNormatif/uniteDeGestion/VP_historique.csv":
        "modeleNormatif/uniteDeDefinitionDuVP.gaml",
    "modeleHydrographique/zonesHydrographiques/debitEntre.csv":
        "modeleHydrographique/zoneHydrographique.gaml",
    "modeleHydrographique/zonesHydrographiques/debitEntreObs.csv":
        "modeleHydrographique/zoneHydrographique.gaml",
    "modeleAgricole/marcheAgricole/rendementsObservesAnterieur.csv":
        "modeleAgricole/Agriculteurs/memoire.gaml",
}
for _nom in (
    "ASAForfaitDebit", "ASAForfaitSurface", "ASAPrixEau", "chargesDePassage",
    "chargesFixesAccesRessourceIrrigation", "chargesFixesMaterielIrrigation",
    "chargesOp", "primes", "prixEau", "redevanceEau",
):
    DYNAMIQUES[f"modeleAgricole/marcheAgricole/{_nom}.csv"] = "modeleAgricole/marcheAgricole.gaml"


def condition(spec_id: str, module: str) -> str | None:
    """Condition d'applicabilite : celle du module ET celle du fichier.

    Une condition propre au fichier PRECISE celle du module, elle ne la remplace
    pas : donneesMNT_ZH n'est attendu que si l'hydrographie tourne ET en mode SWAT.
    """
    parties = [c for c in (REQUIRED_IF_MODULE.get(module), REQUIRED_IF_SPEC.get(spec_id)) if c]
    return " && ".join(parties) if parties else None


def identifiant(chemin: str) -> str:
    """modeleAgricole/culture/reglesDeDecisions.csv -> agri.culture.reglesDeDecisions"""
    segments = chemin.split("/")
    prefixe = PREFIXE_MODULE.get(segments[0], segments[0])
    reste = segments[1:]
    reste[-1] = reste[-1].rsplit(".", 1)[0]
    return ".".join([prefixe, *reste])


def nature(nom: str) -> str:
    ext = nom.rsplit(".", 1)[-1].lower()
    return {
        "csv": "CSV", "shp": "SHAPEFILE", "png": "IMAGE", "gif": "IMAGE", "txt": "TEXT"
    }.get(ext, "TEXT")


def lignes_csv(chemin: pathlib.Path) -> list[list[str]]:
    texte = None
    for encodage in ("utf-8-sig", "latin-1"):
        try:
            texte = chemin.read_text(encoding=encodage)
            break
        except UnicodeDecodeError:
            continue
    if texte is None:
        return []
    brutes = [l for l in texte.splitlines() if l.strip()]
    if not brutes:
        return []
    delim = ";" if brutes[0].count(";") >= brutes[0].count(",") else ","
    return [[c.strip().strip('"') for c in l.split(delim)] for l in brutes]


def champs_dbf(chemin: pathlib.Path) -> list[str]:
    with chemin.open("rb") as f:
        f.seek(8)
        taille = struct.unpack("<H", f.read(2))[0]
        f.seek(32)
        noms = []
        for _ in range((taille - 33) // 32):
            bloc = f.read(32)
            if not bloc or bloc[0] == 0x0D:
                break
            noms.append(bloc[:11].split(b"\x00")[0].decode("latin-1").strip())
    return noms


def analyse_tabulaire(chemin: pathlib.Path, spec_id: str) -> tuple[str, int | None, list[str]]:
    """Renvoie (orientation, matrix_value_start_index, champs).

    L'orientation vient de la table ORIENTATIONS ; seuls les NOMS des champs sont
    lus dans le fichier. Pour un fichier transpose, ce sont les valeurs de la
    colonne 0 — elles peuvent se repeter (plusieurs operations du meme type par
    ITK), l'identite d'un champ y est donc sa position.
    """
    lignes = lignes_csv(chemin)
    if not lignes:
        return (*DEFAUT_ORIENTATION, [])

    orientation, depart = ORIENTATIONS.get(spec_id, DEFAUT_ORIENTATION)
    if orientation == "FIELDS_AS_ROWS":
        return orientation, depart, [l[0].strip() for l in lignes if l and l[0].strip()]
    return orientation, depart, [c.strip() for c in lignes[0] if c.strip()]


def chemins_lus() -> dict[str, str]:
    """Chemins litteraux lus par le code, hors lignes commentees."""
    frag = re.compile(r"['\"](/[^'\"]*\.(?:csv|shp|dbf|txt|png))['\"]")
    trouves: dict[str, str] = {}
    for f in sorted(MODELS.rglob("*.gaml")):
        for ligne in f.read_text(encoding="utf-8", errors="replace").splitlines():
            if "cheminModeleVersDonnees" in ligne and not ligne.strip().startswith("//"):
                for m in frag.findall(ligne):
                    trouves.setdefault(
                        m.lstrip("/"), str(f.relative_to(MODELS)).replace("\\", "/")
                    )
    trouves.pop("md5sum.txt", None)
    trouves.update(DYNAMIQUES)
    return trouves


# Jeu de référence : le seul dont on ait la preuve qu'il mène un run à terme
# (un an, ~140 s, 9 fichiers de sortie). Les autres passent après, et ne
# servent que pour un fichier qu'il ne porterait pas.
REFERENCE_TERRITORY = "terrainTest"


def territories(root):
    """Les jeux livrés, le jeu de référence en tête."""
    if not root.is_dir():
        return []
    found = [d for d in root.iterdir() if d.is_dir() and not d.name.startswith(".")]
    return sorted(found, key=lambda d: (d.name != REFERENCE_TERRITORY, d.name))


# ── Obligatoire ou facultatif ───────────────────────────────────────────────
# Le modèle le dit lui-même, de quatre façons :
#   lecture directe, aucune garde                      -> obligatoire
#   `if !file_exists(X) { raiseError }`   il s'arrête  -> obligatoire
#   `if !file_exists(X) { raiseWarning }` il prévient  -> facultatif
#   `if (file_exists(X)) { ... }`         il continue  -> facultatif
#
# Deux pièges : le dossier est parfois une variable
# (`cheminMarcheAgricole + 'primes.csv'`), et chercher le seul nom de fichier en
# sous-chaine confond `ZH.shp` avec `altitudeAgregeesParZH.shp`. On cherche donc
# un littéral qui se **termine** par le nom du fichier.
AFFECTATION = re.compile(r"(?:^|\s)(?:\w+\s+)?(?P<var>[A-Za-z_]\w*)\s*<-")


def lignes_gaml() -> list[tuple[str, int, str]]:
    lignes = []
    for chemin in sorted(MODELS.rglob("*.gaml")):
        for numero, ligne in enumerate(
            chemin.read_text(encoding="utf-8", errors="replace").splitlines(), 1
        ):
            if not ligne.strip().startswith("//"):
                lignes.append((str(chemin.relative_to(MODELS)).replace("\\", "/"), numero, ligne))
    return lignes


def actions_prudentes(lignes: list[tuple[str, int, str]]) -> set[str]:
    """Actions qui verifient l'existence du fichier qu'on leur passe.

    `lectureDonneEcoParNatureDeRessource(string Chemin, ...)` ouvre son corps par
    `if (file_exists(Chemin))` : tout fichier passe a cette action est lu
    prudemment, meme si aucune garde n'entoure sa variable. Sans ce relais, une
    dizaine de fichiers economiques passeraient pour obligatoires alors que le
    modele tourne sans eux.
    """
    entete = re.compile(r"\baction\s+(?P<nom>\w+)\s*\((?P<params>[^)]*)")
    prudentes: set[str] = set()

    for index, (_, _, ligne) in enumerate(lignes):
        trouve = entete.search(ligne)
        if trouve is None:
            continue
        params = re.findall(r"string\s+(\w+)", trouve.group("params"))
        if not params:
            continue
        corps = []
        for _, _, suite in lignes[index + 1 : index + 60]:
            if entete.search(suite):
                break
            corps.append(suite)
        texte = " ".join(corps)
        if any(re.search(r"file_exists\s*\(\s*" + re.escape(p) + r"\s*\)", texte) for p in params):
            prudentes.add(trouve.group("nom"))

    return prudentes


# Une lecture peut etre enfermee dans un bloc garde par l'existence d'un AUTRE
# fichier : `if(file_exists(communesShape)){ ... csv_file(cheminSalaireCommunes) }`.
# Sans communes, ces fichiers ne sont jamais ouverts.
PORTEE_BLOC = 20


def _sous_garde(lignes: list[tuple[str, int, str]], index: int) -> bool:
    """La ligne est-elle dans un bloc ouvert par un `if (file_exists(...))` ?"""
    fichier = lignes[index][0]
    for _, _, precedente in reversed(lignes[max(0, index - PORTEE_BLOC) : index]):
        if ENTETE_ACTION.search(precedente):
            return False
        if re.search(r"if\s*\(?\s*file_exists\s*\(", precedente) and "!" not in precedente:
            return True
    return False


# Une action se declare avec ou sans parentheses : `action f(string x){` comme
# `action initialisationCommunes{`. Exiger la parenthese faisait manquer la
# moitie des actions du modele.
ENTETE_ACTION = re.compile(r"\baction\s+(?P<nom>\w+)\s*[({]")


def _action_englobante(lignes, index: int) -> str | None:
    """Nom de l'action qui contient cette ligne."""
    fichier = lignes[index][0]
    for f, _, precedente in reversed(lignes[:index]):
        if f != fichier:
            return None
        trouve = ENTETE_ACTION.search(precedente)
        if trouve:
            return trouve.group("nom")
    return None


def _appels_tous_gardes(lignes, action: str) -> bool:
    """Cette action n'est-elle appelee que depuis un bloc garde ?

    `initialisationCommunes` lit son fichier sans precaution, mais elle n'est
    appelee que sous `if(file_exists(communesShape))` : sans communes, le
    fichier n'est jamais ouvert.
    """
    appel = re.compile(r"\bdo\s+" + re.escape(action) + r"\s*[(;]")
    sites = [i for i, (_, _, ligne) in enumerate(lignes) if appel.search(ligne)]
    return bool(sites) and all(_sous_garde(lignes, i) for i in sites)


def est_obligatoire(
    nom: str, lignes: list[tuple[str, int, str]], prudentes: set[str] = frozenset()
) -> bool:
    """Le modele s'arrete-t-il si ce fichier manque ?

    Les tests suivent ce que le code dit, du plus direct au plus indirect :

      1. variable jamais reprise ailleurs -> le fichier n'est pas lu : facultatif
      2. lue seulement dans output/       -> depend d'une sortie : facultatif
      3. passee a une action qui verifie son existence -> facultatif
      4. toutes ses lectures sont dans un bloc `if (file_exists(...))` -> facultatif
      5. `if !file_exists(X) { raiseError }`   -> obligatoire
         `raiseWarning`, ou `if (file_exists(X))` -> facultatif
      6. lue sans aucune garde            -> obligatoire

    Ce verdict dit « ce fichier etant attendu, peut-on demarrer sans lui ». Il ne
    dit pas s'il est attendu : c'est `required_if` qui porte la condition de
    module, et l'applicabilite est calculee avant d'arriver ici.
    """
    porteur = re.compile(r"""['"](?:[^'"]*/)?""" + re.escape(nom) + r"""['"]""")
    variables: set[str] = set()
    litterales: list[int] = []

    for index, (_, _, ligne) in enumerate(lignes):
        if not porteur.search(ligne):
            continue
        trouve = AFFECTATION.search(ligne)
        if trouve is None and index > 0:
            # Chemin ecrit sur deux lignes : l'affectation est au-dessus.
            precedente = lignes[index - 1][2]
            if precedente.rstrip().endswith(("+", "<-")):
                trouve = AFFECTATION.search(precedente)
        if trouve and "file_exists" not in ligne:
            variables.add(trouve.group("var"))
        else:
            litterales.append(index)

    if litterales and not variables:
        # Lecture en toutes lettres : la garde ne peut venir que du bloc, ou de
        # l'action qui la contient.
        if all(_sous_garde(lignes, i) for i in litterales):
            return False
        actions = {_action_englobante(lignes, i) for i in litterales}
        actions.discard(None)
        return not (actions and all(_appels_tous_gardes(lignes, a) for a in actions))
    if not variables:
        return False

    emplois: dict[str, list[tuple[str, str, int]]] = {}
    for var in variables:
        mot = re.compile(r"\b" + re.escape(var) + r"\b")
        affectation = re.compile(r"\b" + re.escape(var) + r"\s*<-")
        emplois[var] = [
            (fichier, ligne, index)
            for index, (fichier, _, ligne) in enumerate(lignes)
            if mot.search(ligne) and not affectation.search(ligne)
        ]

    utilisees = {var for var, ou in emplois.items() if ou}
    if not utilisees:
        return False  # declaree, jamais lue : le fichier n'est pas ouvert

    toutes = [entree for var in utilisees for entree in emplois[var]]
    if all(fichier.startswith("output/") for fichier, _, _ in toutes):
        return False  # lue pour produire une sortie, pas pour demarrer

    appel = re.compile(r"\bdo\s+(\w+)\s*\(")
    if prudentes and all(
        any(action in prudentes for action in appel.findall(ligne)) for _, ligne, _ in toutes
    ):
        return False

    if all(_sous_garde(lignes, index) for _, _, index in toutes):
        return False

    englobantes = {_action_englobante(lignes, index) for _, _, index in toutes}
    englobantes.discard(None)
    if englobantes and all(_appels_tous_gardes(lignes, a) for a in englobantes):
        return False

    # La garde la plus contraignante l'emporte : le modele essaie parfois
    # plusieurs emplacements et ne leve l'erreur qu'au dernier.
    gardee = False
    for var in sorted(utilisees):
        garde = re.compile(r"file_exists\s*\(\s*" + re.escape(var) + r"\s*\)")
        for index, (_, _, ligne) in enumerate(lignes):
            if not garde.search(ligne):
                continue
            gardee = True
            voisinage = " ".join(l for _, _, l in lignes[index : index + 3])
            if re.search(r"!\s*file_exists", ligne) and "raiseError" in voisinage:
                return True

    if gardee:
        return False

    return True


def main() -> int:
    if not MODELS.is_dir():
        print(f"modele introuvable : {MODELS}", file=sys.stderr)
        return 1

    # Les en-tetes viennent du jeu de reference ; un autre jeu ne depanne que
    # pour un fichier qu'il ne porterait pas.
    territoires = territories(INCLUDES)
    gaml = lignes_gaml()
    prudentes = actions_prudentes(gaml)
    specs: list[dict] = []

    # Deux fichiers de meme nom mais d'extension differente (canaux.csv et
    # canaux.shp) donneraient le meme identifiant : on suffixe alors par le type.
    tous = sorted(chemins_lus().items())
    collisions = collections.Counter(identifiant(c) for c, _ in tous)

    for chemin, source in tous:
        spec_id = identifiant(chemin)
        if collisions[spec_id] > 1:
            spec_id = f"{spec_id}_{chemin.rsplit('.', 1)[-1].lower()}"
        dossier, nom_fichier = chemin.rsplit("/", 1)
        module = chemin.split("/")[0]
        kind = nature(nom_fichier)

        spec = {
            "id": spec_id,
            "label": nom_fichier,
            "module": module,
            "kind": kind,
            "relative_dir": dossier,
            "file_name": nom_fichier,
            "file_name_pattern": None,
            "orientation": None,
            "delimiter": ";",
            "has_header": True,
            "matrix_value_start_index": None,
            "required": est_obligatoire(nom_fichier, gaml, prudentes),
            "required_if": condition(spec_id, module),
            "depends_on": DEPENDS_ON.get(spec_id, []),
            "gaml_source": source,
            "fields": [],
        }

        for racine in territoires:
            if kind == "CSV":
                fichier = racine / chemin
                if fichier.is_file():
                    orientation, start, champs = analyse_tabulaire(fichier, spec_id)
                    spec["orientation"] = orientation
                    spec["matrix_value_start_index"] = start
                    spec["fields"] = champs
                    break
            elif kind == "SHAPEFILE":
                dbf = racine / chemin.replace(".shp", ".dbf")
                if dbf.is_file():
                    spec["fields"] = champs_dbf(dbf)
                    break
        specs.append(spec)

    for spec_id, (dossier, motif, libelle, obligatoire) in MULTI_INSTANCE.items():
        specs = [s for s in specs if s["id"] != spec_id]
        module = dossier.split("/")[0]
        specs.append({
            "id": spec_id,
            "label": libelle,
            "module": module,
            "kind": "CSV",
            "relative_dir": dossier,
            "file_name": None,
            "file_name_pattern": motif,
            "orientation": "FIELDS_AS_COLUMNS",
            "delimiter": ";",
            "has_header": True,
            "matrix_value_start_index": None,
            "required": obligatoire,
            "required_if": condition(spec_id, module),
            "depends_on": DEPENDS_ON.get(spec_id, []),
            "gaml_source": None,
            "fields": [],
        })

    doublons = [i for i, n in collections.Counter(s["id"] for s in specs).items() if n > 1]
    if doublons:
        print(f"identifiants en double : {doublons}", file=sys.stderr)
        return 1

    specs.sort(key=lambda s: s["id"])
    SORTIE.parent.mkdir(parents=True, exist_ok=True)
    SORTIE.write_text(json.dumps(specs, ensure_ascii=False, indent=2), encoding="utf-8")

    avec_champs = sum(1 for s in specs if s["fields"])
    transposes = sum(1 for s in specs if s["orientation"] == "FIELDS_AS_ROWS")
    print(f"{len(specs)} specs -> {SORTIE.relative_to(RACINE)}")
    print(
        f"  champs renseignes : {avec_champs} | transposes : {transposes} | "
        f"multi-instances : {len(MULTI_INSTANCE)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
