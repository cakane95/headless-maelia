"""Project context boundaries."""

import uuid
from typing import Protocol

from app.contexts.project.domain.models import FileStatus, Project


class ProjectRepository(Protocol):
    async def list_all(self) -> list[Project]: ...

    async def get(self, project_id: uuid.UUID) -> Project | None: ...

    async def save(self, project: Project) -> Project: ...

    async def delete(self, project_id: uuid.UUID) -> bool: ...


class DatasetInventoryPort(Protocol):
    """State of a project's data, as seen from the `dataset` context.

    This port spares the project any knowledge of dataset persistence: it asks
    for a state, not for rows. It is also what makes completion computable in a
    test without a database.
    """

    async def inventory(self, project_id: uuid.UUID) -> dict[str, dict[str, FileStatus]]: ...
