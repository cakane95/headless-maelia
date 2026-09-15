"""Saved readings — SQLAlchemy adapter."""

import uuid

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.contexts.result.domain.models import Aggregate, ChartType, OutputView, SeriesQuery
from app.contexts.result.infrastructure.persistence import OutputViewRow


def _to_domain(row: OutputViewRow) -> OutputView:
    stored = row.query or {}
    return OutputView(
        id=row.id,
        project_id=row.project_id,
        name=row.name,
        file_name=row.file_name,
        chart=ChartType(row.chart),
        query=SeriesQuery(
            x=stored.get("x", ""),
            measures=tuple(stored.get("measures") or ()),
            series_by=stored.get("series_by"),
            aggregate=Aggregate(stored.get("aggregate", Aggregate.MEAN)),
            filters={k: tuple(v) for k, v in (stored.get("filters") or {}).items()},
            limit=stored.get("limit", 500),
        ),
        created_at=row.created_at,
    )


def _to_json(query: SeriesQuery) -> dict:
    return {
        "x": query.x,
        "measures": list(query.measures),
        "series_by": query.series_by,
        "aggregate": query.aggregate.value,
        "filters": {k: list(v) for k, v in query.filters.items()},
        "limit": query.limit,
    }


class SqlOutputViewRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def list_for_project(self, project_id: uuid.UUID) -> list[OutputView]:
        result = await self._session.execute(
            select(OutputViewRow)
            .where(OutputViewRow.project_id == project_id)
            .order_by(OutputViewRow.created_at)
        )
        return [_to_domain(row) for row in result.scalars()]

    async def save(self, view: OutputView) -> OutputView:
        """Upsert by name: saving twice under the same name updates the reading
        instead of leaving two chips that look identical."""
        existing = await self._session.execute(
            select(OutputViewRow).where(
                OutputViewRow.project_id == view.project_id, OutputViewRow.name == view.name
            )
        )
        row = existing.scalar_one_or_none()
        if row is None:
            row = OutputViewRow(id=view.id, project_id=view.project_id, name=view.name)
            self._session.add(row)

        row.file_name = view.file_name
        row.chart = view.chart.value
        row.query = _to_json(view.query)
        await self._session.flush()
        await self._session.refresh(row)
        return _to_domain(row)

    async def delete(self, view_id: uuid.UUID) -> None:
        await self._session.execute(delete(OutputViewRow).where(OutputViewRow.id == view_id))
