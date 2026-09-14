"""Reading and summarising an output table. Pure functions, no I/O.

Two jobs:

  * **profile** — decide what each column is good for. A chart cannot be offered
    before knowing which columns are numeric and which are categorical, and the
    model states neither: it has to be inferred from the values.
  * **aggregate** — turn rows into series. MAELIA writes one row per plot and per
    period; a readable chart almost always sums or averages over something.
"""

import csv
import io
import re
from collections import defaultdict
from collections.abc import Iterable, Mapping, Sequence

from app.contexts.result.domain.models import (
    Aggregate,
    Column,
    ColumnRole,
    Series,
    SeriesQuery,
    SeriesResult,
    TableProfile,
)

ENCODINGS = ("utf-8-sig", "utf-8", "latin-1")
DELIMITERS = (";", ",", "\t", "|")

# `N_lixivie[kgN/ha]`, `surface [m2]` — the unit only ever appears in the header.
UNIT_RE = re.compile(r"^(?P<label>.+?)\s*\[(?P<unit>[^\]]+)\]\s*$")

# Names that order an axis. Matched on the name, because their values are plain
# integers that a numeric test would happily call a measure.
TEMPORAL_HINTS = (
    "annee", "année", "year", "date", "jour", "day", "mois", "month",
    "semaine", "week", "cycle", "time",
)

# Share of parsable values above which a column counts as numeric. Not 100%:
# MAELIA leaves cells empty when an operation does not apply to a row.
NUMERIC_RATIO = 0.8
SAMPLE = 40  # distinct values kept per dimension, enough to fill a filter list


def decode(payload: bytes) -> str:
    for encoding in ENCODINGS:
        try:
            return payload.decode(encoding)
        except UnicodeDecodeError:
            continue
    return payload.decode("latin-1", errors="replace")


def sniff(text: str) -> str:
    """Delimiter of the first line — the one that splits it into most fields."""
    head = text.splitlines()[0] if text else ""
    return max(DELIMITERS, key=head.count) if head else ";"


def read_table(payload: bytes) -> tuple[tuple[str, ...], list[tuple[str, ...]]]:
    """Header and rows of a delimited file. Short rows are padded, never dropped."""
    text = decode(payload)
    reader = csv.reader(io.StringIO(text), delimiter=sniff(text))
    rows = [tuple(cell.strip() for cell in row) for row in reader if any(row)]
    if not rows:
        return (), []

    header = rows[0]
    width = len(header)
    body = [row[:width] + ("",) * (width - len(row)) for row in rows[1:]]
    return header, body


def as_number(value: str) -> float | None:
    """Numeric reading of a cell. A lone decimal comma is a decimal point here."""
    text = value.strip()
    if not text:
        return None
    if "," in text and "." not in text:
        text = text.replace(",", ".")
    try:
        return float(text)
    except ValueError:
        return None


def split_unit(header: str) -> tuple[str, str | None]:
    found = UNIT_RE.match(header.strip())
    return (found.group("label"), found.group("unit")) if found else (header.strip(), None)


def infer_role(name: str, values: Sequence[str]) -> ColumnRole:
    lowered = name.lower()
    if any(hint in lowered for hint in TEMPORAL_HINTS):
        return ColumnRole.TEMPORAL

    filled = [v for v in values if v.strip()]
    if not filled:
        return ColumnRole.DIMENSION

    numeric = sum(1 for v in filled if as_number(v) is not None)
    return ColumnRole.MEASURE if numeric / len(filled) >= NUMERIC_RATIO else ColumnRole.DIMENSION


def profile(header: Sequence[str], rows: Sequence[Sequence[str]]) -> TableProfile:
    """What each column is, and which values a dimension takes."""
    columns = []
    for index, raw in enumerate(header):
        values = [row[index] for row in rows if index < len(row)]
        label, unit = split_unit(raw)
        role = infer_role(raw, values)
        distinct = sorted({v for v in values if v.strip()}, key=_sort_key)
        columns.append(
            Column(
                name=raw,
                label=label,
                unit=unit,
                role=role,
                distinct=len(distinct),
                values=tuple(distinct[:SAMPLE]) if role is not ColumnRole.MEASURE else (),
            )
        )
    return TableProfile(columns=tuple(columns), row_count=len(rows))


def _sort_key(value: str) -> tuple[int, float, str]:
    """Order an axis numerically when it can be, alphabetically otherwise."""
    number = as_number(value)
    return (0, number, "") if number is not None else (1, 0.0, value)


def _combine(values: list[float], how: Aggregate) -> float:
    if how is Aggregate.COUNT:
        return float(len(values))
    if not values:
        return 0.0
    if how is Aggregate.SUM:
        return sum(values)
    if how is Aggregate.MIN:
        return min(values)
    if how is Aggregate.MAX:
        return max(values)
    return sum(values) / len(values)


def _keep(record: Mapping[str, str], filters: Mapping[str, Sequence[str]]) -> bool:
    return all(
        not allowed or record.get(name, "") in allowed for name, allowed in filters.items()
    )


def build_series(
    header: Sequence[str],
    rows: Iterable[Sequence[str]],
    query: SeriesQuery,
) -> SeriesResult:
    """Aggregate rows into the series a chart draws.

    Values are gathered per (x, category, measure) then combined in one pass, so
    the cost stays linear in the number of rows whatever the chart asks for.
    """
    index = {name: position for position, name in enumerate(header)}
    missing = [name for name in (query.x, *query.measures) if name not in index]
    if missing:
        raise KeyError(", ".join(missing))

    buckets: dict[tuple[str, str | None, str], list[float]] = defaultdict(list)
    axis: set[str] = set()

    for row in rows:
        record = {n: row[p] for n, p in index.items() if p < len(row)}
        if not _keep(record, query.filters):
            continue
        x = record.get(query.x, "").strip()
        if not x:
            continue
        axis.add(x)
        category = record.get(query.series_by) if query.series_by else None
        for measure in query.measures:
            value = as_number(record.get(measure, ""))
            if value is not None:
                buckets[(x, category, measure)].append(value)
            elif query.aggregate is Aggregate.COUNT:
                buckets[(x, category, measure)].append(0.0)

    ordered = sorted(axis, key=_sort_key)
    truncated = len(ordered) > query.limit
    ordered = ordered[: query.limit]

    categories = sorted({key[1] for key in buckets if key[1] is not None}, key=_sort_key)
    series = [
        Series(
            measure=measure,
            category=category,
            points=tuple(
                (x, _combine(buckets[(x, category, measure)], query.aggregate))
                for x in ordered
                if (x, category, measure) in buckets
            ),
        )
        for category in (categories or [None])
        for measure in query.measures
    ]

    return SeriesResult(
        x=query.x,
        x_values=tuple(ordered),
        series=tuple(s for s in series if s.points),
        truncated=truncated,
    )
