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
