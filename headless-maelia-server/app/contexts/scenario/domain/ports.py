"""Scenario context boundaries."""

import uuid
from typing import Protocol

from app.contexts.scenario.domain.models import Scenario


class ScenarioRepository(Protocol):
    async def list_for_project(self, project_id: uuid.UUID) -> list[Scenario]: ...

    async def get(self, scenario_id: uuid.UUID) -> Scenario | None: ...

    async def save(self, scenario: Scenario) -> Scenario: ...

    async def delete(self, scenario_id: uuid.UUID) -> bool: ...
