"""Generate the scenario-parameter catalog from `launcherBase.gaml`.

The launcher is the reference: it is the exact list of variables that can be
overridden in a `load` sent to gama-server. Anything not declared there cannot be
changed by a scenario.

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
LAUNCHER = (
    RACINE / "gama-models" / "MAELIA_1.4.29_GAMA_2025-06" / "models" / "main" / "launcherBase.gaml"
)
OUTPUT = (
    pathlib.Path(__file__).resolve().parents[1]
    / "app/contexts/catalog/infrastructure/seed/parameters.json"
)

# `parameter 'Label' var: name <- default;`
PARAMETER = re.compile(
    r"^\s*parameter\s+(['\"])(?P<label>.*?)\1\s+var:\s*(?P<name>\w+)\s*<-\s*(?P<default>.+?);",
    re.M,
)
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


def main() -> int:
    if not LAUNCHER.is_file():
        print(f"launcher not found: {LAUNCHER}", file=sys.stderr)
        return 1

    text = LAUNCHER.read_text(encoding="utf-8", errors="replace")
    parameters: list[dict] = []
    seen: set[str] = set()

    for match in PARAMETER.finditer(text):
        name = match.group("name")
        if name in seen:
            # The launcher declares a few parameters twice (commented variants);
            # the first declaration is the one GAMA keeps.
            continue
        seen.add(name)

        kind, default = infer_type(match.group("default"))
        label = match.group("label").strip().rstrip(":").strip() or name

        parameters.append({
            "name": name,
            "label": label,
            "group": group_of(text, match.start()),
            "type": kind,
            "default": default,
            "system": name in SYSTEM_PARAMETERS,
            # An EXPRESSION default is not a value we can offer for editing.
            "editable": kind != "EXPRESSION" and name not in SYSTEM_PARAMETERS,
            "options_from": OPTION_SOURCES.get(name),
        })

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(parameters, ensure_ascii=False, indent=2), encoding="utf-8")

    by_type: dict[str, int] = {}
    for parameter in parameters:
        by_type[parameter["type"]] = by_type.get(parameter["type"], 0) + 1
    editable = sum(1 for p in parameters if p["editable"])

    print(f"{len(parameters)} parameters -> {OUTPUT.relative_to(RACINE)}")
    print(f"  editable: {editable} | system: {len(SYSTEM_PARAMETERS)} | types: {by_type}")
    print(f"  groups: {sorted({p['group'] for p in parameters})}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
