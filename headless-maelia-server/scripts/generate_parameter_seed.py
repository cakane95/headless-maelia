"""Generate the scenario-parameter catalog from the MAELIA launchers.

Two launchers, two roles:

  - `launcherBase.gaml` says **which** variables exist. It is the exact list of
    what can be overridden in a `load` sent to gama-server, and `launcherTest`
    — the launcher the platform actually runs — declares exactly the same 149.
    Anything absent from it cannot be changed by a scenario.

  - `launcherSasseme.gaml` says **what they are worth**. Its defaults are the
    ones calibrated by the modellers on a real study, and they are the ones the
    platform offers. It declares 140 of the 149: a variable it omits keeps the
    value `launcherBase` gives it, and a variable it alone declares is ignored,
    because `launcherTest` would not accept it.

Types and groups are inferred from the file itself:
  - the type comes from the default value (`false` -> bool, `2019` -> int, ...);
  - the group comes from the nearest banner comment above the parameter.

Usage (from the repository root):
    python headless-maelia-server/scripts/generate_parameter_seed.py
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

RACINE = pathlib.Path(__file__).resolve().parents[2]
MAIN = RACINE / "gama-models" / "MAELIA_1.4.29_GAMA_2025-06" / "models" / "main"
# Qui declare les variables, et donc ce qu'un scenario peut surcharger.
LAUNCHER = MAIN / "launcherBase.gaml"
# Qui donne les valeurs par defaut retenues.
LAUNCHER_DEFAUTS = MAIN / "launcherSasseme.gaml"
OUTPUT = (
    pathlib.Path(__file__).resolve().parents[1]
    / "app/contexts/catalog/infrastructure/seed/parameters.json"
)

# `parameter 'Label' var: name <- default;`
PARAMETER = re.compile(
    r"^\s*parameter\s+(['\"])(?P<label>.*?)\1\s+var:\s*(?P<name>\w+)\s*<-\s*(?P<default>.+?);",
    re.M,
)
# Ce que `launcherSasseme` regle pour SON territoire, et qui ne designe rien
# ailleurs : le territoire lui-meme, ses zones hydrographiques, et les annees
# que ses donnees couvrent. Verifie par l'execution : `anneeDebutSimulation`
# a 2018 fait echouer un run sur terrainTest, dont la meteo commence en 2019.
# Les parametres a `options_from` sont ecartes pour la meme raison, mais le
# catalogue les designe deja : leurs valeurs vivent dans les donnees du projet.
PROPRES_AU_TERRITOIRE = {
    "nomDecoupageZonePourLectureFichiers",
    "listNomsZHsDecoupageZone",
    "anneeDebutSimulation",
    "anneeDeReferenceRPG",
    # Le modele de croissance des prairies decide quelles especes fourrageres
    # existent. Sasseme tourne en AqYield ; les ITK de terrainTest citent
    # `lolMul`, que seul HerbSim declare — un run echoue alors a l'initialisation
    # sur « l'espece lolMul n'existe pas ». Le choix est donc lie aux donnees du
    # territoire, pas au gout du modelisateur.
    "nomChoixModeleCroissancePrairie",
    # Un interrupteur qui commande une liste propre au territoire ne s'en
    # separe pas : pris seul, il restreint la simulation a des exploitations
    # qui n'existent pas, et le run s'arrete sur « 0 exploitation creee ».
    "executerSurEnsembleExploit",
    "listAgriASuivre",
    # terrainTest ne porte pas de modeleNormatif : pas de barrages a gerer.
    "executerBarrage",
    # Prefixe des cultures intermediaires dans le fichier d'especes. Sasseme
    # ecrit « ci- », terrainTest « ci » : c'est une convention de nommage de
    # donnees, pas un reglage.
    "PREFIXE_CI",
    # Ces deux-la decrivent la FORME du fichier d'itineraires techniques du
    # territoire — combien de fertilisations, combien de traitements par ITK.
    # Les changer sans changer le fichier le rend illisible.
    "plusieursFertilisationsParITK",
    "plusieursTraitementsPhytoParITK",
}

# Banner comments delimiting the sections of the launcher.
BANNER = re.compile(r"/\*\s*-{4,}\s*(?P<title>[^-*]+?)\s*-{4,}", re.I)

# Parameters the platform imposes on every run: exposing them to the user would
# have no effect, the worker overrides them (see worker/tasks.py).
SYSTEM_PARAMETERS = {
    "executerSurCluster",
    "cheminRacineMaelia",
    "cheminModeleVersDonnees",
    "cheminRelatifDuDossierDeSortieDeSimulation",
    "idSimulationAPI",
}

# Parameters whose value designates something living in a data file.
#
# The launcher does not say it: `idExploitationAexecuter` expects an identifier
# that must exist in `exploitations.csv`, and only a reading of the model tells
# which column. The mapping is therefore explicit here rather than guessed at
# runtime — the same choice as ORIENTATIONS in the file catalog.
#
# Format `<data_spec_id>#<field>`; an empty field means the options are the file
# **instances** (one price-scenario file per scenario), not a column.
#
# Each entry below was checked against the shipped `terrainTest` data: the
# parameter default is one of the values the source actually contains.
OPTION_SOURCES = {
    "idExploitationAexecuter": "agri.agriculteurs.exploitations#ID_EXPL",
    "listIdExploitationAexecuter": "agri.agriculteurs.exploitations#ID_EXPL",
    "nomParcelleAffichee": "agri.ilots.dansZone.parcelles#ID_PARCELL",
    "listParcellesASuivre": "agri.ilots.dansZone.parcelles#ID_PARCELL",
    "listParcellesPourSortiesAqYield": "agri.ilots.dansZone.parcelles#ID_PARCELL",
    "idSdcForce": "agri.ilots.dansZone.parcelles#ID_SDC",
    "listScenarioPrix": "agri.marcheAgricole.prixVentes#",
    "scenarioDePrixPrincipal": "agri.marcheAgricole.prixVentes#",
}

# Dependances entre parametres : un parametre n'a de sens que si un autre est actif.
#
# Le launcher les documente lui-meme, par un commentaire « si oui » place entre
# le booleen qui commande et le parametre commande :
#
#     // simulation sur une seule exploitation
#     parameter '...' var: executerUnSeulAgriculteur <- false;
#     // si oui id de l'exploitation a simuler
#     parameter '...' var: idExploitationAexecuter   <- "mineral_beauce_29";
#
# On les lit donc au lieu de les recopier. Piege : un commentaire qui dit « si
# oui » ET « si non » decrit les deux branches du parametre lui-meme, pas une
# dependance — `associerIlotMeteoZH` en est le cas.
DEPENDANCE = re.compile(r"\bsi\s+oui\b", re.I)
AUTODESCRIPTION = re.compile(r"\bsi\s+non\b", re.I)

# Ce que le launcher ne dit pas en toutes lettres. Le bloc « parametrage d'une
# parcelle virtuelle » commande les cinq parametres qui le suivent, sans
# commentaire par parametre.
DEPENDANCES_EXPLICITES = {
    "rotationForceeParcelle": "executerParcelleVirtuelle == true",
    "gestionPaillesForceeParcelle": "executerParcelleVirtuelle == true",
    "idSdcForce": "executerParcelleVirtuelle == true",
    "typeDeSolForceParcelle": "executerParcelleVirtuelle == true",
    "surfaceHectareForceParcelle": "executerParcelleVirtuelle == true",
}


def dependances(texte: str) -> dict[str, str]:
    """Condition d'activite de chaque parametre, lue dans le launcher.

    Retourne `{parametre: "commandant == true"}`. Seul un booleen peut commander
    : « si oui » n'a de sens que la-dessus.
    """
    lignes = texte.splitlines()
    declaration = {}
    for index, ligne in enumerate(lignes):
        trouve = PARAMETER.match(ligne)
        if trouve:
            declaration[index] = (trouve.group("name"), trouve.group("default").strip())

    conditions: dict[str, str] = {}
    precedent = None
    for index in sorted(declaration):
        nom, _ = declaration[index]

        commentaires = []
        curseur = index - 1
        while curseur >= 0 and lignes[curseur].strip().startswith("//"):
            commentaires.insert(0, lignes[curseur].strip("/ \t"))
            curseur -= 1
        bloc = " ".join(commentaires)

        commande = precedent and precedent[1] in {"true", "false"}
        if commande and DEPENDANCE.search(bloc) and not AUTODESCRIPTION.search(bloc):
            conditions[nom] = f"{precedent[0]} == true"

        precedent = declaration[index]

    conditions.update(DEPENDANCES_EXPLICITES)
    return conditions


GROUP_LABELS = {
    "CHEMINS SELON EXECUTION EN LOCAL OU SUR CLUSTER": "Chemins",
    "PARAMETRES GENERAUX": "Général",
    "PARAMETRES MODELE HYDROLOGIQUE": "Modèle hydrographique",
    "PARAMETRES MODELE AGRICOLE": "Modèle agricole",
    "PARAMETRES MODELE FILIERE": "Modèle filière",
    "PARAMETRES MODELE NORMATIF": "Modèle normatif",
    "SORTIES": "Sorties",
    "ASSOLEMENT": "Sorties — assolement",
    "BILAN HYDRIQUE": "Sorties — bilan hydrique",
    "ECONOMIE": "Sorties — économie",
    "BIODIVERSITE": "Sorties — biodiversité",
    "HYDROLOGIE": "Sorties — hydrologie",
    "PRELEVEMENTS": "Sorties — prélèvements",
    "NORMATIF": "Sorties — normatif",
    "OPÉRATIONS TECHNIQUES": "Sorties — opérations techniques",
}


def infer_type(default: str) -> tuple[str, object]:
    """Return (type, parsed default) from the GAML literal."""
    raw = default.strip()

    if raw in ("true", "false"):
        return "BOOL", raw == "true"
    if raw.startswith("["):
        return "LIST", _parse_list(raw)
    if raw.startswith(("'", '"')):
        return "STRING", raw[1:-1]
    if re.fullmatch(r"-?\d+", raw):
        return "INT", int(raw)
    if re.fullmatch(r"-?\d*\.\d+", raw):
        return "FLOAT", float(raw)

    # An expression (map lookup, reference to another variable): keep it as text,
    # the platform will not offer it for editing.
    return "EXPRESSION", raw


def _parse_list(raw: str) -> list[str]:
    inner = raw.strip()[1:-1].strip()
    if not inner:
        return []
    return [item.strip().strip("'\"") for item in inner.split(",")]


def group_of(text: str, position: int) -> str:
    """Nearest banner above the parameter."""
    last = "Général"
    for banner in BANNER.finditer(text):
        if banner.start() > position:
            break
        title = banner.group("title").strip().upper()
        last = GROUP_LABELS.get(title, title.capitalize())
    return last


def defaults_from(launcher: pathlib.Path) -> dict[str, str]:
    """Raw default expressions declared by a launcher, keyed by variable name.

    Only the first declaration counts: the launchers carry commented variants
    further down, and GAMA keeps the first.
    """
    if not launcher.is_file():
        return {}
    text = launcher.read_text(encoding="utf-8", errors="replace")
    raw: dict[str, str] = {}
    for match in PARAMETER.finditer(text):
        raw.setdefault(match.group("name"), match.group("default"))
    return raw


def main() -> int:
    if not LAUNCHER.is_file():
        print(f"launcher not found: {LAUNCHER}", file=sys.stderr)
        return 1

    text = LAUNCHER.read_text(encoding="utf-8", errors="replace")
    retenus = defaults_from(LAUNCHER_DEFAUTS)
    if not retenus:
        print(f"launcher of defaults not found: {LAUNCHER_DEFAUTS}", file=sys.stderr)
        return 1
    repris = 0
    conditions = dependances(text)
    parameters: list[dict] = []
    seen: set[str] = set()

    for match in PARAMETER.finditer(text):
        name = match.group("name")
        if name in seen:
            # The launcher declares a few parameters twice (commented variants);
            # the first declaration is the one GAMA keeps.
            continue
        seen.add(name)

        # La valeur vient du launcher de reference quand il declare la
        # variable ; sinon on garde celle de launcherBase.
        declare = match.group("default")
        transposable = name not in PROPRES_AU_TERRITOIRE and name not in OPTION_SOURCES
        brut = retenus[name] if transposable and name in retenus else declare
        kind, default = infer_type(brut)
        # Ce que le launcher execute declare, quand il dit autre chose. Sans
        # cette trace, un defaut du catalogue resterait lettre morte : seuls les
        # ecarts voyagent jusqu'a GAMA, et un defaut n'en est pas un.
        _, declare_typed = infer_type(declare)
        impose = declare_typed if brut != declare else None
        if impose is not None:
            repris += 1
        label = match.group("label").strip().rstrip(":").strip() or name

        parameters.append({
            "name": name,
            "label": label,
            "group": group_of(text, match.start()),
            "type": kind,
            "default": default,
            "launcher_default": impose,
            "system": name in SYSTEM_PARAMETERS,
            # An EXPRESSION default is not a value we can offer for editing.
            "editable": kind != "EXPRESSION" and name not in SYSTEM_PARAMETERS,
            "options_from": OPTION_SOURCES.get(name),
            "enabled_if": conditions.get(name),
        })

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(parameters, ensure_ascii=False, indent=2), encoding="utf-8")

    by_type: dict[str, int] = {}
    for parameter in parameters:
        by_type[parameter["type"]] = by_type.get(parameter["type"], 0) + 1
    editable = sum(1 for p in parameters if p["editable"])

    ecartes = sorted(
        (PROPRES_AU_TERRITOIRE | set(OPTION_SOURCES)) & set(retenus)
    )
    absents = sorted({p["name"] for p in parameters} - set(retenus))
    print(f"{len(parameters)} parameters -> {OUTPUT.relative_to(RACINE)}")
    print(f"  editable: {editable} | system: {len(SYSTEM_PARAMETERS)} | types: {by_type}")
    print(f"  defauts repris de {LAUNCHER_DEFAUTS.name} : {repris} modifies, "
          f"{len(absents)} absents donc inchanges")
    if absents:
        print("  absents de sasseme :", ", ".join(absents))
    print(f"  ecartes car propres au territoire sasseme : {len(ecartes)}")
    if ecartes:
        print("   ", ", ".join(ecartes))
    print(f"  groups: {sorted({p['group'] for p in parameters})}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
