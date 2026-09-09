"""SQLAlchemy adapter of the scenario context."""

import uuid

from sqlalchemy import delete as sql_delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.contexts.scenario.domain.models import Scenario
from app.contexts.scenario.infrastructure.persistence import ScenarioRow


def _to_domain(row: ScenarioRow) -> Scenario:
    return Scenario(
        id=row.id,
        project_id=row.project_id,
        name=row.name,
        description=row.description,
        parameter_values=dict(row.parameter_values or {}),
        dataset_pins=dict(row.dataset_pins or {}),
        created_at=row.created_at,
        updated_at=row.updated_at,
    )


class SqlScenarioRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def list_for_project(self, project_id: uuid.UUID) -> list[Scenario]:
        result = await self._session.execute(
            select(ScenarioRow)
            .where(ScenarioRow.project_id == project_id)
            .order_by(ScenarioRow.created_at.desc())
        )
        return [_to_domain(r) for r in result.scalars()]

    async def get(self, scenario_id: uuid.UUID) -> Scenario | None:
        row = await self._session.get(ScenarioRow, scenario_id)
        return _to_domain(row) if row else None

    async def save(self, scenario: Scenario) -> Scenario:
        row = await self._session.get(ScenarioRow, scenario.id)
        if row is None:
            row = ScenarioRow(id=scenario.id, project_id=scenario.project_id)
            self._session.add(row)
        row.name = scenario.name
        row.description = scenario.description
        row.parameter_values = scenario.parameter_values
        row.dataset_pins = scenario.dataset_pins
        await self._session.flush()
        # `updated_at` is database-computed: expired after the flush, and reading
        # it back would trigger a lazy load, which async forbids.
        await self._session.refresh(row)
        return _to_domain(row)

    async def delete(self, scenario_id: uuid.UUID) -> bool:
        result = await self._session.execute(
            sql_delete(ScenarioRow).where(ScenarioRow.id == scenario_id)
        )
        return result.rowcount > 0
