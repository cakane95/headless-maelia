"""Output routes — SIMULATION domain.

The platform does not know a MAELIA output column: it reads the file, says what
each column can do, proposes charts that follow from that, and answers one
generic series query. A new output file is therefore usable without a deployment.
"""

import uuid
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Query
from fastapi.responses import Response
from pydantic import BaseModel, Field

from app.contexts.result.application import use_cases
from app.contexts.result.domain.models import (
    Aggregate,
    ChartType,
    ColumnRole,
    OutputKind,
    SeriesQuery,
)
from app.contexts.result.infrastructure.file_store import FileOutputStore
from app.contexts.run.infrastructure import redis_store as runs
from app.shared.errors import NotFoundError, ValidationError

router = APIRouter(prefix="/api/v1", tags=["results"])


def store() -> FileOutputStore:
    return FileOutputStore()


Store = Annotated[FileOutputStore, Depends(store)]


async def _run(run_id: str) -> dict[str, Any]:
    run = await runs.get(run_id)
    if run is None:
        raise NotFoundError(f"run introuvable : {run_id}")
    return run


# ── HTTP schemas ────────────────────────────────────────────────────────────

class OutputFileOut(BaseModel):
    name: str
    size: int
    kind: OutputKind


class ColumnOut(BaseModel):
    name: str
    label: str
    unit: str | None
    role: ColumnRole
    distinct: int
    values: list[str]


class SeriesQueryIn(BaseModel):
    """A chart, as data. The same body serves one run or a comparison."""

    x: str
    measures: list[str] = Field(min_length=1)
    series_by: str | None = None
    aggregate: Aggregate = Aggregate.MEAN
    filters: dict[str, list[str]] = Field(default_factory=dict)
    limit: int = Field(default=500, ge=1, le=5000)

    def to_query(self) -> SeriesQuery:
        return SeriesQuery(
            x=self.x,
            measures=tuple(self.measures),
            series_by=self.series_by,
            aggregate=self.aggregate,
            filters={k: tuple(v) for k, v in self.filters.items()},
            limit=self.limit,
        )


class SuggestionOut(BaseModel):
    title: str
    chart: ChartType
    reason: str
    query: SeriesQueryIn


class ProfileOut(BaseModel):
    name: str
    row_count: int
    columns: list[ColumnOut]
    suggestions: list[SuggestionOut]


class SeriesOut(BaseModel):
    x: str
    x_values: list[str]
    keys: list[str]
    rows: list[dict[str, Any]]
    truncated: bool


class ComparisonEntryOut(BaseModel):
    run_id: str
    label: str
    series: SeriesOut


def _render_series(result) -> SeriesOut:
    return SeriesOut(
        x=result.x,
        x_values=list(result.x_values),
        keys=[s.key for s in result.series],
        rows=result.as_rows(),
        truncated=result.truncated,
    )


def _render_suggestion(suggestion) -> SuggestionOut:
    query = suggestion.query
    return SuggestionOut(
        title=suggestion.title,
        chart=suggestion.chart,
        reason=suggestion.reason,
        query=SeriesQueryIn(
            x=query.x,
            measures=list(query.measures),
            series_by=query.series_by,
            aggregate=query.aggregate,
            limit=query.limit,
        ),
    )


# ── One run ─────────────────────────────────────────────────────────────────

@router.get("/runs/{run_id}/outputs", response_model=list[OutputFileOut])
async def list_outputs(store: Store, run_id: str) -> list[OutputFileOut]:
    files = await use_cases.list_outputs(store, await _run(run_id))
    return [OutputFileOut(name=f.name, size=f.size, kind=f.kind) for f in files]


@router.get("/runs/{run_id}/outputs/{name}/profile", response_model=ProfileOut)
async def profile_output(store: Store, run_id: str, name: str) -> ProfileOut:
    """Columns of a file and the charts they support."""
    table, suggestions = await use_cases.profile_output(store, await _run(run_id), name)
    return ProfileOut(
        name=name,
        row_count=table.row_count,
        columns=[
            ColumnOut(
                name=c.name, label=c.label, unit=c.unit, role=c.role,
                distinct=c.distinct, values=list(c.values),
            )
            for c in table.columns
        ],
        suggestions=[_render_suggestion(s) for s in suggestions],
    )


@router.get("/runs/{run_id}/outputs/{name}/preview")
async def preview_output(
    store: Store, run_id: str, name: str,
    limit: Annotated[int, Query(ge=1, le=500)] = 50,
) -> dict[str, Any]:
    return await use_cases.preview_output(store, await _run(run_id), name, limit)


@router.get("/runs/{run_id}/outputs/{name}/text")
async def read_text(store: Store, run_id: str, name: str) -> dict[str, str]:
    return {"content": await use_cases.read_text(store, await _run(run_id), name)}


@router.get("/runs/{run_id}/outputs/{name}/download")
async def download_output(store: Store, run_id: str, name: str) -> Response:
    payload = await store.read(await _run(run_id), name)
    return Response(
        content=payload,
        media_type="application/octet-stream",
        headers={"Content-Disposition": f'attachment; filename="{name}"'},
    )


@router.post("/runs/{run_id}/outputs/{name}/series", response_model=SeriesOut)
async def series(store: Store, run_id: str, name: str, payload: SeriesQueryIn) -> SeriesOut:
    result = await use_cases.build_series(store, await _run(run_id), name, payload.to_query())
    return _render_series(result)


# ── Several runs ────────────────────────────────────────────────────────────

class ComparisonIn(BaseModel):
    file_name: str
    run_ids: list[str] = Field(min_length=1, max_length=8)
    query: SeriesQueryIn


@router.post(
    "/projects/{project_id}/output-comparison", response_model=list[ComparisonEntryOut]
)
async def compare(
    store: Store, project_id: uuid.UUID, payload: ComparisonIn
) -> list[ComparisonEntryOut]:
    """The same chart over several runs of the project.

    Comparing two scenarios is the reason the platform freezes data versions:
    without this endpoint, that guarantee would have no reading.
    """
    selected = []
    for run_id in payload.run_ids:
        run = await _run(run_id)
        if run.get("project_id") != str(project_id):
            raise ValidationError(f"le run {run_id} n'appartient pas à ce projet")
        selected.append(run)

    results = await use_cases.compare_runs(
        store, selected, payload.file_name, payload.query.to_query()
    )
    return [
        ComparisonEntryOut(run_id=run["id"], label=run.get("label") or run["id"],
                           series=_render_series(result))
        for run, result in results
    ]
