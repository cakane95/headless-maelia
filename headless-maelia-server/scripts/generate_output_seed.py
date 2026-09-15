"""Produit le catalogue des sorties a partir du GAML du modele.

Trois fichiers portent l'information, et aucun ne la porte seule :

* `output/selectionOutput.gaml` declare les drapeaux, leur defaut, et les
  commente au format « theme ; fichier csv ; [pas][resolution] description » ;
* `output/ecritureResultats.gaml` fait l'aiguillage — c'est lui, et lui seul,
  qui dit sous quelles conditions un module d'ecriture est cree ;
* `output/<module>.gaml` compose le nom reel du fichier et son pas de temps.

Le resultat est `app/contexts/catalog/infrastructure/seed/outputs.json`.

Usage : `python scripts/generate_output_seed.py [--verifier]`
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys
from dataclasses import dataclass, field

RACINE = pathlib.Path(__file__).resolve().parents[2]
MODELES = RACINE / "gama-models" / "MAELIA_1.4.29_GAMA_2025-06" / "models"
SORTIES = MODELES / "output"
AIGUILLAGE = SORTIES / "ecritureResultats.gaml"
SELECTION = SORTIES / "selectionOutput.gaml"
GLOBALES = MODELES / "modeleCommun" / "donneesGlobales.gaml"
CIBLE = (
    pathlib.Path(__file__).resolve().parents[1]
    / "app" / "contexts" / "catalog" / "infrastructure" / "seed" / "outputs.json"
)

# Le pas de temps n'est ecrit nulle part ailleurs que dans le nom de la variable
# que le module d'ecriture affecte.
PAS_DE_TEMPS = {
    "nomFichierJournalier": "DAILY",
    "nomFichierDebutAnnuel": "YEAR_START",
    "nomFichierFinAnnuel": "YEAR_END",
    "nomFichierMensuel": "MONTHLY",
    "nomFichierBimensuel": "FORTNIGHTLY",
}

NON_EXPRIMABLE = "<?>"


def lire(chemin: pathlib.Path) -> str:
    """Le modele est en ISO-8859-1 : ses accents ne sont pas de l'UTF-8."""
    return chemin.read_text(encoding="latin-1")


def sans_commentaires(source: str) -> str:
    source = re.sub(r"/\*.*?\*/", " ", source, flags=re.S)
    return re.sub(r"//[^\n]*", "", source)


# ── 1. Les constantes du modele ──────────────────────────────────────────────

def constantes() -> dict[str, str]:
    """`string AqYield <- 'AqYield' const: true;` — les gardes comparent a ces
    variables, pas a des litteraux."""
    texte = lire(GLOBALES)
    return {
        nom: valeur
        for nom, valeur in re.findall(
            r"^\s*string\s+(\w+)\s*<-\s*'([^']*)'\s*const:\s*true", texte, re.M
        )
    }


def variables_du_modele() -> set[str]:
    """Les variables globales sur lesquelles une garde peut porter.

    Le filtre sert a ecarter ce qui n'en est pas une : `name = '3451'` dans un
    `ask` designe un agent, pas un reglage, et le traduire en condition ferait
    predire n'importe quoi.
    """
    globales = sans_commentaires(lire(GLOBALES))
    noms = set(re.findall(r"^\s*(?:bool|string|int|float)\s+(\w+)\s*<-", globales, re.M))
    # Le launcher expose des variables declarees ailleurs que dans
    # donneesGlobales ; les drapeaux de sortie vivent dans selectionOutput.
    launcher = sans_commentaires(lire(MODELES / "main" / "launcherBase.gaml"))
    noms |= set(re.findall(r"var:\s*(\w+)", launcher))
    noms |= set(drapeaux())
    return noms


# ── 2. Les drapeaux et leur commentaire ──────────────────────────────────────

@dataclass
class Drapeau:
    nom: str
    defaut: bool
    theme: str
    description: str | None = None


def drapeaux() -> dict[str, Drapeau]:
    """Les booleens de `selectionOutput.gaml`, avec le theme qui les precede.

    Les themes sont marques par `/* ---- ASSOLEMENT ---- */` ; la description
    est le commentaire qui precede immediatement la declaration.
    """
    texte = lire(SELECTION)
    theme = "DIVERS"
    releves: dict[str, Drapeau] = {}
    commentaire: list[str] = []

    for ligne in texte.splitlines():
        nue = ligne.strip()

        marque = re.match(r"/\*\s*-{3,}\s*(.+?)\s*-{3,}\s*\*/", nue)
        if marque:
            theme = marque.group(1).strip()
            commentaire.clear()
            continue

        if nue.startswith("//"):
            commentaire.append(nue.lstrip("/").strip())
            continue

        declaration = re.match(r"bool\s+(\w+)\s*<-\s*(true|false)", nue)
        if declaration:
            releves[declaration.group(1)] = Drapeau(
                nom=declaration.group(1),
                defaut=declaration.group(2) == "true",
                theme=theme,
                description=_description(commentaire),
            )
            commentaire.clear()
            continue

        if nue and not nue.startswith("/*"):
            commentaire.clear()

    return releves


def _description(lignes: list[str]) -> str | None:
    """« theme ; fichier ; [pas][resolution] description » — on garde la fin.

    Le format est tenu par les auteurs du modele ; quand il ne l'est pas, le
    commentaire entier fait une description acceptable.
    """
    if not lignes:
        return None
    entier = " ".join(lignes).strip()
    morceaux = entier.split(";")
    texte = morceaux[-1].strip() if len(morceaux) >= 3 else entier
    return re.sub(r"\s+", " ", texte) or None


# ── 3. Les fichiers que chaque action d'initialisation produit ───────────────

@dataclass
class Module:
    action: str
    source: str
    fichiers: list[tuple[str, str]] = field(default_factory=list)  # (nom, pas)


def modules() -> dict[str, Module]:
    """Pour chaque `action initialisation…`, les noms de fichiers reels.

    L'action cree une espece ; c'est l'espece qui compose les noms. Passer par
    le `create` evite de confondre deux modules loges dans le meme fichier.
    """
    releves: dict[str, Module] = {}

    for chemin in sorted(SORTIES.glob("*.gaml")):
        texte = sans_commentaires(lire(chemin))
        especes = _especes(texte)
        relatif = f"output/{chemin.name}"

        for action, corps in _actions_globales(texte):
            module = Module(action=action, source=relatif)
            for espece in re.findall(r"\bcreate\s+(\w+)", corps):
                module.fichiers.extend(_fichiers(especes.get(espece, "")))
            if not module.fichiers and len(especes) == 1:
                # Un module qui cree son espece autrement : une seule espece dans
                # le fichier ne laisse aucune ambiguite.
                module.fichiers.extend(_fichiers(next(iter(especes.values()))))
            releves[action] = module

    return releves


def _actions_globales(texte: str) -> list[tuple[str, str]]:
    """Les actions `initialisation…` et leur corps, accolades equilibrees."""
    trouvees = []
    for entete in re.finditer(r"\baction\s+(initialisation\w+)\s*(?:\([^)]*\))?\s*\{", texte):
        trouvees.append((entete.group(1), _bloc(texte, entete.end() - 1)))
    return trouvees


def _especes(texte: str) -> dict[str, str]:
    """Le corps de chaque `species … parent: ecritureResultats`."""
    releves = {}
    for entete in re.finditer(r"\bspecies\s+(\w+)\s+parent:\s*ecritureResultats\s*\{", texte):
        releves[entete.group(1)] = _bloc(texte, entete.end() - 1)
    return releves


def _bloc(texte: str, debut: int) -> str:
    """Le contenu entre l'accolade ouvrante en `debut` et sa fermante."""
    profondeur = 0
    for position in range(debut, len(texte)):
        if texte[position] == "{":
            profondeur += 1
        elif texte[position] == "}":
            profondeur -= 1
            if profondeur == 0:
                return texte[debut + 1 : position]
    return texte[debut + 1 :]


def _fichiers(corps: str) -> list[tuple[str, str]]:
    """Les `nomFichierX <- … + '/nom' … '.csv';` du corps d'une espece."""
    trouves = []
    motif = re.compile(
        r"(nomFichier\w+)\s*<-\s*cheminRelatifDuDossierDeSortieDeSimulation\s*\+\s*"
        r"'([^']*)'(.*?);",
        re.S,
    )
    for affectation in motif.finditer(corps):
        variable, debut, suite = affectation.groups()
        nom = debut.lstrip("/")
        # `'/sorties_eau' + nomDeLaSimulation + '.csv'` : le suffixe est vide
        # depuis 1.4.29, l'extension est le dernier litteral de la chaine.
        for litteral in re.findall(r"'([^']*)'", suite):
            nom += litteral
        if nom and (nom, PAS_DE_TEMPS.get(variable, "UNKNOWN")) not in trouves:
            trouves.append((nom, PAS_DE_TEMPS.get(variable, "UNKNOWN")))
    return trouves


# ── 4. Les gardes de l'aiguillage ────────────────────────────────────────────

def gardes() -> dict[str, list[str]]:
    """Pour chaque action appelee, la pile de conditions qui l'entoure.

    C'est la seule lecture qui repond a « pourquoi ce fichier manque-t-il ? » :
    le drapeau ne suffit pas, il est imbrique dans les gardes des modules dont
    la sortie depend.
    """
    texte = sans_commentaires(lire(AIGUILLAGE))
    entete = re.search(r"\baction\s+initialisationEcritureFichiers\s*\{", texte)
    if entete is None:
        raise SystemExit("aiguillage introuvable dans ecritureResultats.gaml")

    corps = _bloc(texte, entete.end() - 1)
    releves: dict[str, list[str]] = {}
    _parcourir(corps, _APPEL, [], releves)
    return releves


_APPEL = re.compile(r"\bdo\s+(initialisation\w+)\s*\(")
_SI = re.compile(r"\bif\s*(?=[\S])")


def _parcourir(
    source: str, motif: re.Pattern[str], pile: list[str], releves: dict[str, list[str]]
) -> None:
    """Descend dans les `if`, en tenant la pile des conditions traversees.

    `motif` dit ce qu'on cherche : l'appel d'un module d'ecriture dans
    l'aiguillage, ou l'ecriture directe d'un fichier ailleurs dans le modele.
    """
    position = 0
    while position < len(source):
        si = _SI.search(source, position)
        appel = motif.search(source, position)

        if si is None and appel is None:
            return
        if si is not None and (appel is None or si.start() < appel.start()):
            condition, ouvrante = _condition(source, si.end())
            if ouvrante is None:  # `if x { … }` mal forme : on ne devine pas
                position = si.end()
                continue
            bloc = _bloc(source, ouvrante)
            _parcourir(bloc, motif, pile + [condition], releves)
            position = ouvrante + len(bloc) + 2
            continue

        releves.setdefault(appel.group(1), list(pile))
        position = appel.end()


def _condition(source: str, depart: int) -> tuple[str, int | None]:
    """La condition d'un `if`, jusqu'a l'accolade qui ouvre son bloc."""
    position = depart
    while position < len(source) and source[position] in " \t\r\n":
        position += 1

    profondeur = 0
    debut = position
    while position < len(source):
        caractere = source[position]
        if caractere == "(":
            profondeur += 1
        elif caractere == ")":
            profondeur -= 1
            if profondeur < 0:
                return source[debut:position].strip(), None
        elif caractere == "{" and profondeur == 0:
            return source[debut:position].strip(), position
        position += 1
    return source[debut:].strip(), None


# ── 4 bis. Les fichiers ecrits hors aiguillage ───────────────────────────────

# `save <quelque chose> to: <destination>;` — la destination est soit une
# variable, soit directement le chemin compose.
_ECRITURE = re.compile(r"(\bsave\b[^;{}]{0,400}?\bto:[^;{}]{0,200};)", re.S)
_DESTINATION = re.compile(
    r"cheminRelatifDuDossierDeSortieDeSimulation\s*\+\s*[\"']([^\"']*)[\"']"
)


def hors_aiguillage() -> list[dict]:
    """Les fichiers que le modele ecrit sans passer par `ecritureResultats`.

    `simulationParameters.txt`, `surfaceParcelles.csv` et leurs voisins sont
    ecrits directement, au fil du code. Sans eux, l'ecran de resultats les
    presenterait comme « hors catalogue » alors qu'ils sont parfaitement
    attendus.

    On n'enregistre que les fichiers reellement sauvegardes : `nbAgentsPerDay`
    a sa variable mais son `save` est commente, il n'existe pas.
    """
    constantes_connues = constantes()
    acceptables = variables_du_modele()
    releves: list[dict] = []
    vus: set[str] = set()

    for chemin in sorted(MODELES.rglob("*.gaml")):
        if chemin.is_relative_to(SORTIES):
            continue
        texte = sans_commentaires(lire(chemin))
        if "cheminRelatifDuDossierDeSortieDeSimulation" not in texte:
            continue

        affectations = [
            (trouve.start(), trouve.group(1), trouve.group(2))
            for trouve in _AFFECTATION.finditer(texte)
        ]
        ecritures: dict[str, list[str]] = {}
        _parcourir(texte, _ECRITURE, [], ecritures)

        for instruction, pile in ecritures.items():
            # `fileName` sert deux fois dans main.gaml, pour deux fichiers : la
            # bonne valeur est celle affectee juste avant l'ecriture.
            noms = _noms_avant(affectations, texte.find(instruction))
            nom = _destination(instruction, noms)
            if nom is None or "." not in nom or nom in vus:
                continue
            vus.add(nom)
            expression = " and ".join(f"({condition})" for condition in pile)
            produced_if, exact = (
                traduire(expression, constantes_connues, acceptables) if expression else ("", True)
            )
            releves.append({
                "nom": nom,
                "produced_if": produced_if or None,
                "guard_source": expression or None,
                "exact": exact,
                "source": chemin.relative_to(MODELES).as_posix(),
            })

    return releves


_AFFECTATION = re.compile(
    r"\b(\w+)\s*<-\s*cheminRelatifDuDossierDeSortieDeSimulation\s*\+\s*[\"']([^\"']*)[\"']"
)


def _noms_avant(
    affectations: list[tuple[int, str, str]], position: int
) -> dict[str, str]:
    """Ce que valait chaque variable de chemin a cet endroit du fichier."""
    noms: dict[str, str] = {}
    for depart, variable, valeur in affectations:
        if position < 0 or depart <= position:
            noms[variable] = valeur
    return noms


def _destination(instruction: str, noms: dict[str, str]) -> str | None:
    """Le fichier qu'une instruction `save` ecrit, ou None si ce n'est pas un
    fichier de sortie de simulation."""
    directe = _DESTINATION.search(instruction)
    if directe:
        return directe.group(1).lstrip("/")

    cible = re.search(r"\bto:\s*\(?\s*(\w+)", instruction)
    if cible and cible.group(1) in noms:
        return noms[cible.group(1)].lstrip("/")
    return None


# ── 5. Traduction GAML → langage de conditions du catalogue ──────────────────

def traduire(
    expression: str,
    constantes_connues: dict[str, str],
    variables: set[str] | None = None,
) -> tuple[str, bool]:
    """Rend l'expression en forme normale disjonctive, et dit si c'est exact.

    Le langage du catalogue n'a ni parentheses ni appels : `&&` lie plus fort
    que `||`, ce qui suffit des lors qu'on distribue. Un terme intraduisible
    (`length(listeCanaux) > 0`) est retire — la prediction devient alors plus
    permissive que le modele, et c'est `exact = False` qui le signale.
    """
    alternatives = _distribuer(_analyser(expression))
    exact = True
    rendues = []

    for conjonction in alternatives:
        termes = []
        for terme in conjonction:
            rendu = _terme(terme, constantes_connues, variables)
            if rendu is None:
                exact = False
                continue
            if rendu not in termes:
                termes.append(rendu)
        rendues.append(termes)

    # Une alternative vidée de tous ses termes est toujours vraie : la garde
    # entière l'est alors aussi, et l'annoncer serait plus honnête que de rendre
    # une expression vide.
    if any(not termes for termes in rendues):
        return "", False

    uniques: list[list[str]] = []
    for termes in rendues:
        if termes not in uniques:
            uniques.append(termes)
    return " || ".join(" && ".join(termes) for termes in uniques), exact


def _analyser(expression: str) -> list:
    """Arbre `('or', …)` / `('and', …)` / chaine, en respectant les parentheses."""
    expression = expression.strip()
    while expression.startswith("(") and _appariee(expression):
        expression = expression[1:-1].strip()

    for operateur, etiquette in (("or", "or"), ("and", "and")):
        morceaux = _couper(expression, operateur)
        if len(morceaux) > 1:
            return [etiquette] + [_analyser(morceau) for morceau in morceaux]
    return expression


def _appariee(expression: str) -> bool:
    """La premiere parenthese se ferme-t-elle a la toute fin ?"""
    if not expression.startswith("("):
        return False
    profondeur = 0
    for position, caractere in enumerate(expression):
        profondeur += (caractere == "(") - (caractere == ")")
        if profondeur == 0:
            return position == len(expression) - 1
    return False


def _couper(expression: str, operateur: str) -> list[str]:
    """Decoupe au niveau zero de parenthese, sur `and` / `or` isoles."""
    morceaux, profondeur, debut = [], 0, 0
    motif = re.compile(rf"\b{operateur}\b")
    position = 0
    while position < len(expression):
        caractere = expression[position]
        if caractere == "(":
            profondeur += 1
        elif caractere == ")":
            profondeur -= 1
        elif profondeur == 0:
            trouve = motif.match(expression, position)
            if trouve:
                morceaux.append(expression[debut:position])
                position = trouve.end()
                debut = position
                continue
        position += 1
    morceaux.append(expression[debut:])
    return [morceau.strip() for morceau in morceaux if morceau.strip()]


def _distribuer(arbre) -> list[list[str]]:
    """Forme normale disjonctive : une liste de conjonctions."""
    if isinstance(arbre, str):
        return [[arbre]]
    operateur, *operandes = arbre
    if operateur == "or":
        return [conjonction for operande in operandes for conjonction in _distribuer(operande)]

    resultat: list[list[str]] = [[]]
    for operande in operandes:
        resultat = [
            gauche + droite for gauche in resultat for droite in _distribuer(operande)
        ]
    return resultat


_COMPARAISON = re.compile(r"^(?P<gauche>[\w.]+)\s*(?P<op>!=|=)\s*(?P<droite>.+)$")


def _terme(
    terme: str, constantes_connues: dict[str, str], variables: set[str] | None = None
) -> str | None:
    """Un atome GAML en comparaison du catalogue, ou None s'il est intraduisible."""
    terme = terme.strip().rstrip(";").strip()
    while terme.startswith("(") and terme.endswith(")") and _appariee(terme):
        terme = terme[1:-1].strip()

    def connue(nom: str) -> bool:
        return variables is None or nom in variables

    if terme.startswith("!"):
        interieur = terme[1:].strip()
        if re.fullmatch(r"\w+", interieur) and connue(interieur):
            return f"{interieur} != true"
        return None

    if re.fullmatch(r"\w+", terme):
        return f"{terme} == true" if connue(terme) else None

    comparaison = _COMPARAISON.match(terme)
    if comparaison is None:
        return None

    gauche = comparaison["gauche"]
    droite = comparaison["droite"].strip()
    if not re.fullmatch(r"\w+", gauche) or not connue(gauche):
        return None

    operateur = "!=" if comparaison["op"] == "!=" else "=="
    if droite.startswith(("'", '"')):
        return f"{gauche} {operateur} '{droite.strip(chr(39) + chr(34))}'"
    if droite in constantes_connues:
        return f"{gauche} {operateur} '{constantes_connues[droite]}'"
    if droite in {"true", "false"} or re.fullmatch(r"-?\d+(\.\d+)?", droite):
        return f"{gauche} {operateur} {droite}"
    return None


# ── 6. Assemblage ────────────────────────────────────────────────────────────

def construire() -> list[dict]:
    constantes_connues = constantes()
    acceptables = variables_du_modele()
    connus = drapeaux()
    ecritures = modules()
    conditions = gardes()

    par_drapeau: dict[str, dict] = {}

    for action, pile in sorted(conditions.items()):
        module = ecritures.get(action)
        if module is None or not module.fichiers:
            continue

        expression = " and ".join(f"({condition})" for condition in pile) or ""
        produced_if, exact = (
            traduire(expression, constantes_connues, acceptables) if expression else ("", True)
        )

        identifiant = _drapeau_de(pile, connus) or action
        entree = par_drapeau.setdefault(
            identifiant,
            {
                "id": identifiant,
                "label": _libelle(identifiant, connus),
                "theme": connus[identifiant].theme if identifiant in connus else "DIVERS",
                "description": connus[identifiant].description if identifiant in connus else None,
                "flag": identifiant if identifiant in connus else None,
                "default": connus[identifiant].defaut if identifiant in connus else False,
                "files": [],
                "produced_if": produced_if or None,
                "guard_source": expression or None,
                "exact": exact,
                "gaml_source": module.source,
            },
        )

        for nom, pas in module.fichiers:
            if all(fichier["name"] != nom for fichier in entree["files"]):
                entree["files"].append({"name": nom, "granularity": pas})

        # Deux modules derriere le meme drapeau : la sortie existe si l'un ou
        # l'autre s'ecrit, donc les gardes s'ajoutent en alternative.
        if produced_if and entree["produced_if"] and produced_if != entree["produced_if"]:
            entree["produced_if"] = f"{entree['produced_if']} || {produced_if}"
            entree["guard_source"] = f"{entree['guard_source']} or {expression}"
        entree["exact"] = entree["exact"] and exact

    par_drapeau.update(_hors_aiguillage_en_entrees())
    return sorted(par_drapeau.values(), key=lambda entree: (entree["theme"], entree["id"]))


# Les modules du modele se commandent chacun par un interrupteur, et ils gardent
# des sous-arbres entiers du code : c'est la meme convention que pour les
# entrees (`required_if`). Le module d'une sortie n'est pas ecrit dans le seed :
# il se lit dans sa condition, et `OutputSpec.module` le fait.
INTERRUPTEURS = {
    "modeleAgricole": "executerModeleAgricole",
    "modeleHydrographique": "executerModeleHydrographique",
    "modeleNormatif": "executerModeleNormatif",
    "modeleCommun": None,
    "main": None,
}


def _hors_aiguillage_en_entrees() -> dict[str, dict]:
    """Les ecritures directes, mises au meme format que les sorties pilotees.

    L'analyse locale ne voit pas les conditions de l'appelant : un fichier ecrit
    depuis `modeleHydrographique/` n'existe que si ce module tourne, et seule
    l'arborescence le dit. On ajoute donc cette garde-la, qui est sure, et on
    laisse `exact` porter ce qui reste d'incertitude.
    """
    entrees: dict[str, dict] = {}
    for trouvaille in hors_aiguillage():
        racine = trouvaille["source"].split("/")[0]
        interrupteur = INTERRUPTEURS.get(racine)
        gardes_connues = [
            partie
            for partie in (trouvaille["produced_if"], f"{interrupteur} == true" if interrupteur else "")
            if partie
        ]
        identifiant = trouvaille["nom"].rsplit(".", 1)[0]
        entrees[identifiant] = {
            "id": identifiant,
            "label": _libelle(identifiant, {}),
            "theme": "HORS AIGUILLAGE",
            "description": "Écrite directement par le modèle, sans drapeau dédié.",
            "flag": None,
            "default": True,
            "files": [{"name": trouvaille["nom"], "granularity": "UNKNOWN"}],
            "produced_if": " && ".join(gardes_connues) or None,
            "guard_source": trouvaille["guard_source"],
            "exact": trouvaille["exact"],
            "gaml_source": trouvaille["source"],
        }
    return entrees


def _drapeau_de(pile: list[str], connus: dict[str, Drapeau]) -> str | None:
    """Le drapeau qui commande ce module : le dernier terme le nommant.

    Les gardes vont du general au particulier — `executerModeleHydrographique`
    puis `DebistSTH` — donc le plus interieur est celui de la sortie.
    """
    for condition in reversed(pile):
        for mot in reversed(re.findall(r"\w+", condition)):
            if mot in connus:
                return mot
    return None


def _libelle(identifiant: str, connus: dict[str, Drapeau]) -> str:
    """Un titre lisible : le nom du drapeau, aere."""
    if identifiant not in connus:
        identifiant = re.sub(r"^initialisationEcritureFichiers?", "", identifiant)
    espace = re.sub(r"[_]+", " ", identifiant)
    espace = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", " ", espace)
    return espace[:1].upper() + espace[1:]


def main() -> int:
    arguments = argparse.ArgumentParser(description=__doc__)
    arguments.add_argument(
        "--verifier", action="store_true", help="n'ecrit rien, affiche le compte rendu"
    )
    options = arguments.parse_args()

    entrees = construire()
    fichiers = sum(len(entree["files"]) for entree in entrees)
    approximatives = [entree["id"] for entree in entrees if not entree["exact"]]

    print(f"{len(entrees)} sorties, {fichiers} fichiers")
    print(f"conditions approximatives : {len(approximatives)} {approximatives}")
    sans_condition = [entree["id"] for entree in entrees if not entree["produced_if"]]
    print(f"sans condition : {len(sans_condition)} {sans_condition}")

    if options.verifier:
        return 0

    CIBLE.write_text(
        json.dumps(entrees, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"ecrit : {CIBLE.relative_to(pathlib.Path(__file__).resolve().parents[1])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
