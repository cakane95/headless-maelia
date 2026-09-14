"""Result use cases: list, profile, chart, compare.

Reading and aggregating are CPU work on files of a few thousand rows, so both go
through a thread: the event loop keeps serving other runs while a chart is built.
"""

import asyncio
from collections.abc import Sequence
from typing import Any

from app.contexts.result.domain import services, suggest as suggestion_rules
from app.contexts.result.domain.models import (
    ChartSuggestion,
    OutputFile,
    OutputKind,
    SeriesQuery,
    SeriesResult,
    TableProfile,
)
from app.contexts.result.domain.ports import OutputStore
from app.shared.errors import NotFoundError, ValidationError

PREVIEW_ROWS = 50


async def list_outputs(store: OutputStore, run: dict[str, Any]) -> list[OutputFile]:
    return await store.list_files(run)


async def _table(store: OutputStore, run: dict[str, Any], name: str):
    payload = await store.read(run, name)
    header, rows = await asyncio.to_thread(services.read_table, payload)
    if not header:
        raise ValidationError(f"{name} ne contient pas de tableau exploitable")
    return header, rows


async def profile_output(
    store: OutputStore, run: dict[str, Any], name: str
) -> tuple[TableProfile, list[ChartSuggestion]]:
    """What the file contains, and the charts that follow from it."""
    header, rows = await _table(store, run, name)
    table = await asyncio.to_thread(services.profile, header, rows)
    return table, suggestion_rules.suggest(table)


async def preview_output(
    store: OutputStore, run: dict[str, Any], name: str, limit: int = PREVIEW_ROWS
) -> dict[str, Any]:
    """First rows of a table, to show what is being charted."""
    header, rows = await _table(store, run, name)
    return {
        "columns": list(header),
        "rows": [list(row) for row in rows[:limit]],
        "row_count": len(rows),
    }


async def read_text(store: OutputStore, run: dict[str, Any], name: str) -> str:
    return services.decode(await store.read(run, name))


async def build_series(
    store: OutputStore, run: dict[str, Any], name: str, query: SeriesQuery
) -> SeriesResult:
    header, rows = await _table(store, run, name)
    try:
        return await asyncio.to_thread(services.build_series, header, rows, query)
    except KeyError as exc:
        raise ValidationError(f"colonnes absentes de {name} : {exc.args[0]}") from exc


async def compare_runs(
    store: OutputStore,
    runs: Sequence[dict[str, Any]],
    name: str,
    query: SeriesQuery,
) -> list[tuple[dict[str, Any], SeriesResult]]:
    """The same chart across several runs — the point of a scenario comparison.

    Each run is read on its own: a run that never produced the file is skipped
    rather than failing the comparison, because a failed run is a legitimate
    member of a comparison.
    """
    if not runs:
        raise ValidationError("aucun run à comparer")

    results = []
    for run in runs:
        try:
            results.append((run, await build_series(store, run, name, query)))
        except (NotFoundError, ValidationError):
            continue

    if not results:
        raise NotFoundError(f"aucun des runs comparés ne contient {name}")
    return results


def chartable(files: Sequence[OutputFile]) -> list[OutputFile]:
    return [f for f in files if f.kind is OutputKind.TABLE]
