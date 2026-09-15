"""Catalog domain model — pure, no framework dependency.

A `DataSpec` describes **what the model expects**, not what a project holds.
It is the schema; the data itself lives in the `dataset` context.
"""

from dataclasses import dataclass, field
from enum import StrEnum


class FileKind(StrEnum):
    CSV = "CSV"
    SHAPEFILE = "SHAPEFILE"
    IMAGE = "IMAGE"
    TEXT = "TEXT"


class Orientation(StrEnum):
    """Reading direction of a tabular file.

    `FIELDS_AS_ROWS` means transposed: field names sit in the first column and
    each following column describes one entity. That is the layout of
    `especesCultivees.csv` and `reglesDeDecisions.csv`.
    """

    FIELDS_AS_COLUMNS = "FIELDS_AS_COLUMNS"
    FIELDS_AS_ROWS = "FIELDS_AS_ROWS"


class FieldType(StrEnum):
    STRING = "STRING"
    INT = "INT"
    FLOAT = "FLOAT"
    BOOL = "BOOL"
    DATE = "DATE"


# MAELIA writes a literal "NA" for a missing value: that is not a typing error,
# it is the model's convention.
MISSING_MARKERS = {"", "NA", "[NA]", "N/A", "null", "NULL"}


@dataclass(frozen=True, slots=True)
class FieldSpec:
    name: str
    label: str | None = None
    type: FieldType = FieldType.STRING
    required: bool = False
    unit: str | None = None
    allowed_values: tuple[str, ...] = ()
    references_data_spec: str | None = None
    position: int = 0

    def accepts(self, raw: str) -> bool:
        """Is this text an acceptable value for the field?"""
        if raw.strip() in MISSING_MARKERS:
            return not self.required

        if self.allowed_values and raw not in self.allowed_values:
            return False

        match self.type:
            case FieldType.INT:
                return _is_integer(raw)
            case FieldType.FLOAT:
                return _is_decimal(raw)
            case FieldType.BOOL:
                return raw.lower() in {"true", "false", "0", "1", "vrai", "faux"}
            case _:
                return True


def _is_integer(raw: str) -> bool:
    try:
        int(raw.strip())
    except ValueError:
        return False
    return True


def _is_decimal(raw: str) -> bool:
    # The model produces both "2.8" and "2,8" depending on the file.
    try:
        float(raw.strip().replace(",", "."))
    except ValueError:
        return False
    return True


@dataclass(frozen=True, slots=True)
class DataSpec:
    """One kind of input file expected by the model."""

    id: str
    label: str
    module: str
    kind: FileKind
    relative_dir: str
    file_name: str | None = None
    file_name_pattern: str | None = None
    orientation: Orientation | None = None
    delimiter: str = ";"
    has_header: bool = True
    matrix_value_start_index: int | None = None
    required: bool = True
    required_if: str | None = None
    depends_on: tuple[str, ...] = ()
    gaml_source: str | None = None
    origin: str = "SEED"
    fields: tuple[FieldSpec, ...] = field(default_factory=tuple)

    @property
    def multi_instance(self) -> bool:
        """Dynamic-name family: `2018.csv`, `prixVentesSC1.csv`…

        A project may then hold several datasets for this same spec, each one
        identified by its `instance_key`.
        """
        return self.file_name is None

    @property
    def tabular(self) -> bool:
        return self.kind is FileKind.CSV

    def target_path(self, instance_key: str | None = None) -> str:
        """Path relative to the territory, as the model will read it."""
        name = self.file_name or instance_key
        if not name:
            raise ValueError(f"{self.id} is multi-instance: instance_key is required")
        return f"{self.relative_dir}/{name}"


class ParameterType(StrEnum):
    BOOL = "BOOL"
    INT = "INT"
    FLOAT = "FLOAT"
    STRING = "STRING"
    LIST = "LIST"
    # A GAML expression (map lookup, reference to another variable). Kept for
    # traceability, never offered for editing: its value is not a literal.
    EXPRESSION = "EXPRESSION"


@dataclass(frozen=True, slots=True)
class ParameterSpec:
    """One scenario parameter, as `launcherBase.gaml` exposes it.

    The launcher is the reference: a variable it does not declare cannot be
    overridden in a `load`, so it cannot be part of a scenario.
    """

    name: str
    label: str
    group: str
    type: ParameterType
    default: object = None
    allowed_values: tuple[str, ...] = ()
    # Imposed by the platform (paths, run id): overriding it would have no effect.
    system: bool = False
    editable: bool = True
    # Where the acceptable values live, as "<data_spec_id>#<field>". The launcher
    # never says it: `idExploitationAexecuter` expects an identifier that exists
    # in a data file, and only a reading of the model tells which one.
    options_from: str | None = None
    # Condition d'activite : `executerUnSeulAgriculteur == true`. Un parametre
    # inactif est sans effet — le fixer ne change rien a la simulation.
    enabled_if: str | None = None
    origin: str = "SEED"

    def accepts(self, value: object) -> bool:
        """Is this value assignable to the parameter?"""
        if self.allowed_values and str(value) not in self.allowed_values:
            return False

        match self.type:
            case ParameterType.BOOL:
                return isinstance(value, bool)
            case ParameterType.INT:
                # `bool` is an `int` in Python; refuse it so True never passes for 1.
                return isinstance(value, int) and not isinstance(value, bool)
            case ParameterType.FLOAT:
                return isinstance(value, (int, float)) and not isinstance(value, bool)
            case ParameterType.STRING:
                return isinstance(value, str)
            case ParameterType.LIST:
                return isinstance(value, list)
            case _:
                return False

    @property
    def options_source(self) -> tuple[str, str | None] | None:
        """Where the possible values live: (data_spec_id, field).

        A `None` field means the options are the **instances** of a
        multi-instance file — one price-scenario file per scenario — and not
        the values of a column.
        """
        if not self.options_from:
            return None
        spec_id, _, field = self.options_from.partition("#")
        return spec_id, (field or None)

    def gama_type(self) -> str:
        """Type name expected in a gama-server `load` message."""
        return {
            ParameterType.BOOL: "bool",
            ParameterType.INT: "int",
            ParameterType.FLOAT: "float",
            ParameterType.STRING: "string",
            ParameterType.LIST: "list",
        }.get(self.type, "string")


class Granularity(StrEnum):
    """Time step at which a result file is written.

    Read from the variable the output module assigns (`nomFichierJournalier`,
    `nomFichierFinAnnuel`…): the model states the step there and nowhere else.
    """

    DAILY = "DAILY"
    YEAR_START = "YEAR_START"
    YEAR_END = "YEAR_END"
    MONTHLY = "MONTHLY"
    FORTNIGHTLY = "FORTNIGHTLY"
    UNKNOWN = "UNKNOWN"


@dataclass(frozen=True, slots=True)
class OutputFileSpec:
    """One file a result module writes."""

    name: str
    granularity: Granularity = Granularity.UNKNOWN


# Each model module is commanded by one switch, and that switch guards a whole
# subtree of the code — the same convention the input catalog uses for
# `required_if`.
MODULE_SWITCHES = {
    "executerModeleHydrographique": "modeleHydrographique",
    "executerModeleNormatif": "modeleNormatif",
    "executerModeleAgricole": "modeleAgricole",
}


@dataclass(frozen=True, slots=True)
class OutputSpec:
    """One family of result files, and what has to be true for it to be written.

    MAELIA writes nothing by default: every result module sits behind a boolean
    switch, itself nested inside the guards of the modules it needs. Without this
    spec a scenario cannot say what it will produce, and a results screen cannot
    explain a file that is not there.

    `produced_if` is the guard translated into the catalog's condition language;
    `guard_source` keeps the GAML verbatim, because a translation that drops a
    term must remain auditable — `exact` says whether anything was dropped.
    """

    id: str
    label: str
    theme: str
    files: tuple[OutputFileSpec, ...] = ()
    description: str | None = None
    flag: str | None = None
    produced_if: str | None = None
    guard_source: str | None = None
    exact: bool = True
    gaml_source: str | None = None
    origin: str = "SEED"

    @property
    def unconditional(self) -> bool:
        """Written on every run, whatever the scenario says."""
        return not self.produced_if

    @property
    def module(self) -> str:
        """Which model module has to run for this output to exist.

        Read from the condition rather than stored: the module switch is already
        one of its terms, and two copies of the same fact drift apart the day an
        administrator edits the condition.
        """
        for switch, module in MODULE_SWITCHES.items():
            if switch in (self.produced_if or ""):
                return module
        return "modeleCommun"

    @property
    def file_names(self) -> tuple[str, ...]:
        return tuple(f.name for f in self.files)

    def owns(self, file_name: str) -> bool:
        """Is this produced file one of ours?

        `nomDeLaSimulation` is appended to the base name before the extension.
        It has been empty since 1.4.29 — the model now personalises the
        directory instead — but a territory that still sets it would otherwise
        make every file unrecognised.
        """
        for declared in self.file_names:
            if file_name == declared:
                return True
            base, _, extension = declared.rpartition(".")
            if base and file_name.startswith(base) and file_name.endswith(f".{extension}"):
                return True
        return False
