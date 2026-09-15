"""Output model — SIMULATION domain.

A run produces files, not indicators: MAELIA writes wide tables where every row
is an observation (a plot, a year, an operation) and most columns are numeric
measures. Nothing here names a MAELIA file or column — the shape is *read* from
the file, so a new output works the day the model starts writing it.
"""

import uuid
from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from datetime import datetime
from enum import StrEnum
from typing import Any


class OutputKind(StrEnum):
    """What can be done with a file, not what it contains."""

    TABLE = "TABLE"    # delimited, has a header: chartable
    TEXT = "TEXT"      # free text: readable only
    BINARY = "BINARY"  # downloadable only


class ColumnRole(StrEnum):
    """How a column can serve a chart."""

    TEMPORAL = "TEMPORAL"    # ordered axis: year, date, day
    DIMENSION = "DIMENSION"  # categorical: plot, crop, farm
    MEASURE = "MEASURE"      # numeric: what gets aggregated


class ChartType(StrEnum):
    """Readings a series supports. The front end draws them; the domain only
    says which one fits the shape of the data."""

    LINE = "LINE"
    BAR = "BAR"
    STACKED_BAR = "STACKED_BAR"
    AREA = "AREA"
    SCATTER = "SCATTER"


class Aggregate(StrEnum):
    SUM = "SUM"
    MEAN = "MEAN"
    MIN = "MIN"
    MAX = "MAX"
    COUNT = "COUNT"


@dataclass(frozen=True, slots=True)
class OutputFile:
    name: str
    size: int
    kind: OutputKind


@dataclass(frozen=True, slots=True)
class Column:
    """A column of an output table, with what a chart needs to know about it.

    `unit` is extracted from the header itself — MAELIA writes it in brackets
    (`N_lixivie[kgN/ha]`), which is the only place the unit is ever stated.
    """

    name: str
    label: str
    unit: str | None
    role: ColumnRole
    distinct: int
    values: tuple[str, ...] = ()  # sampled distinct values, dimensions only


@dataclass(frozen=True, slots=True)
class TableProfile:
    columns: tuple[Column, ...]
    row_count: int

    def column(self, name: str) -> Column | None:
        return next((c for c in self.columns if c.name == name), None)

    def by_role(self, role: ColumnRole) -> tuple[Column, ...]:
        return tuple(c for c in self.columns if c.role == role)


@dataclass(frozen=True, slots=True)
class SeriesQuery:
    """A chart, expressed as data.

    One query answers "this measure, by this axis, split by that dimension" —
    which covers every chart the platform offers, hence a single endpoint.
    """

    x: str
    measures: tuple[str, ...]
    series_by: str | None = None
    aggregate: Aggregate = Aggregate.MEAN
    filters: Mapping[str, Sequence[str]] = field(default_factory=dict)
    limit: int = 500


@dataclass(frozen=True, slots=True)
class Series:
    """One line or one set of bars: a measure, optionally within a category."""

    measure: str
    category: str | None
    points: tuple[tuple[str, float], ...]

    @property
    def key(self) -> str:
        """Name of the series in a chart legend."""
        return f"{self.category} — {self.measure}" if self.category else self.measure


@dataclass(frozen=True, slots=True)
class ChartSuggestion:
    """A chart the platform proposes on its own, from the shape of the table.

    The point is that an output file nobody has ever configured still opens on
    something readable — the user then adjusts, or builds their own.
    """

    title: str
    chart: ChartType
    query: SeriesQuery
    reason: str


@dataclass(frozen=True, slots=True)
class SeriesResult:
    x: str
    x_values: tuple[str, ...]
    series: tuple[Series, ...]
    truncated: bool = False

    def as_rows(self) -> list[dict[str, Any]]:
        """Points regrouped by x — the shape a chart library expects."""
        keyed = {s.key: dict(s.points) for s in self.series}
        return [
            {"x": x, **{key: points.get(x) for key, points in keyed.items()}}
            for x in self.x_values
        ]


@dataclass(frozen=True, slots=True)
class OutputView:
    """A reading of an output file, saved under a name.

    It travels with its file and its chart type: applying it to another run is
    the whole point, and a query without them would not be replayable.
    """

    id: uuid.UUID
    project_id: uuid.UUID
    name: str
    file_name: str
    chart: ChartType
    query: SeriesQuery
    created_at: datetime | None = None
