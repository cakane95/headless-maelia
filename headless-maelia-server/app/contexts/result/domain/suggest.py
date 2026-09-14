"""Charts proposed from the shape of a table. Pure functions, no I/O.

An output file arrives with no chart configuration and none will ever be written
by hand: there are dozens of columns per file and the list grows with the model.
So the proposal is derived from the profile — which column orders an axis, which
one splits into a readable number of groups, which measures actually vary.

Nothing here knows a MAELIA column name; a new output file is charted the day the
model starts writing it.
"""

from app.contexts.result.domain.models import (
    Aggregate,
    ChartSuggestion,
    ChartType,
    Column,
    ColumnRole,
    SeriesQuery,
    TableProfile,
)

# Beyond this, a legend stops being readable and the chart becomes a smear.
MAX_CATEGORIES = 8
# A measure that takes two values carries no shape: rank the varied ones first.
MIN_VARIETY = 2
MEASURES_PER_CHART = 4


def _axis(table: TableProfile) -> Column | None:
    """Column that orders the axis: a temporal one, else the coarsest dimension.

    A column with a single value orders nothing — hence the `distinct > 1` test,
    which rules out the year column of a one-year simulation.
    """
    temporal = [c for c in table.by_role(ColumnRole.TEMPORAL) if c.distinct > 1]
    if temporal:
        return min(temporal, key=lambda c: c.distinct)

    dimensions = [c for c in table.by_role(ColumnRole.DIMENSION) if 1 < c.distinct <= 60]
    return min(dimensions, key=lambda c: c.distinct) if dimensions else None


def _splitter(table: TableProfile, axis: Column) -> Column | None:
    """Dimension that splits into few enough groups to make a legend."""
    candidates = [
        c
        for c in table.columns
        if c.name != axis.name
        and c.role is not ColumnRole.MEASURE
        and 1 < c.distinct <= MAX_CATEGORIES
    ]
    return max(candidates, key=lambda c: c.distinct) if candidates else None


def _measures(table: TableProfile) -> list[Column]:
    """Measures worth drawing, the most varied first."""
    varied = [c for c in table.by_role(ColumnRole.MEASURE) if c.distinct >= MIN_VARIETY]
    return sorted(varied, key=lambda c: c.distinct, reverse=True)


def suggest(table: TableProfile) -> list[ChartSuggestion]:
    """Up to three readings of the table, from the most direct to the most detailed."""
    axis = _axis(table)
    measures = _measures(table)
    if axis is None or not measures:
        return []

    temporal = axis.role is ColumnRole.TEMPORAL
    line = ChartType.LINE if temporal else ChartType.BAR
    first = measures[0]
    suggestions = [
        ChartSuggestion(
            title=f"{first.label} par {axis.label}",
            chart=line,
            query=SeriesQuery(x=axis.name, measures=(first.name,), aggregate=Aggregate.MEAN),
            reason=f"{axis.label} ordonne l'axe, {first.label} est la mesure la plus variée.",
        )
    ]

    splitter = _splitter(table, axis)
    if splitter is not None:
        suggestions.append(
            ChartSuggestion(
                title=f"{first.label} par {axis.label}, réparti par {splitter.label}",
                chart=ChartType.STACKED_BAR,
                query=SeriesQuery(
                    x=axis.name,
                    measures=(first.name,),
                    series_by=splitter.name,
                    aggregate=Aggregate.SUM,
                ),
                reason=f"{splitter.label} prend {splitter.distinct} valeurs : la répartition reste lisible.",
            )
        )

    # Several measures on one chart only make sense if they share a unit —
    # otherwise the scale of one crushes the others and the reading is false.
    comparable = [c for c in measures if c.unit == first.unit][:MEASURES_PER_CHART]
    if len(comparable) > 1:
        unit = f" ({first.unit})" if first.unit else ""
        suggestions.append(
            ChartSuggestion(
                title=f"Mesures comparables par {axis.label}{unit}",
                chart=line,
                query=SeriesQuery(
                    x=axis.name,
                    measures=tuple(c.name for c in comparable),
                    aggregate=Aggregate.MEAN,
                ),
                reason="Mesures de même unité : leur comparaison directe a un sens.",
            )
        )

    return suggestions
