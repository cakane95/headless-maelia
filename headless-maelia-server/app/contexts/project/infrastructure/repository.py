"""Outbound adapters of the project context."""

import uuid

from sqlalchemy import delete as sql_delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.contexts.project.domain.models import FileStatus, Project
from app.contexts.project.infrastructure.persistence import ProjectRow
from app.shared.config import settings


def _to_domain(row: ProjectRow) -> Project:
    return Project(
        id=row.id,
        name=row.name,
        territory=row.territory,
        description=row.description,
        modeling_config=dict(row.modeling_config or {}),
        created_at=row.created_at,
        updated_at=row.updated_at,
    )


class SqlProjectRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def list_all(self) -> list[Project]:
        result = await self._session.execute(
            select(ProjectRow).order_by(ProjectRow.created_at.desc())
        )
        return [_to_domain(r) for r in result.scalars()]

    async def get(self, project_id: uuid.UUID) -> Project | None:
        row = await self._session.get(ProjectRow, project_id)
        return _to_domain(row) if row else None

    async def save(self, project: Project) -> Project:
        row = await self._session.get(ProjectRow, project.id)
        if row is None:
            row = ProjectRow(id=project.id)
            self._session.add(row)
        row.name = project.name
        row.territory = project.territory
        row.description = project.description
        row.modeling_config = project.modeling_config
        await self._session.flush()
        # `updated_at` is computed by the database (onupdate): after the flush it
        # is expired, and reading it back would trigger a lazy load — forbidden in
        # async. Fetch it explicitly instead.
        await self._session.refresh(row)
        return _to_domain(row)

    async def delete(self, project_id: uuid.UUID) -> bool:
        result = await self._session.execute(
            sql_delete(ProjectRow).where(ProjectRow.id == project_id)
        )
        return result.rowcount > 0


class EmptyInventory:
    """Default inventory, until the `dataset` context is wired in.

    Makes completion computable right away: every file comes back MISSING, which
    is accurate — none has been supplied yet.
    """

    async def inventory(self, project_id: uuid.UUID) -> dict[str, dict[str, FileStatus]]:
        return {}


def available_territories() -> list[str]:
    """Territories shipped with the model, read from the shared volume.

    The reference set comes first: it is the one proven to carry a run through
    to the end, so it is the one a caller taking the first entry should get.
    `.runs` holds the per-run working copies, it is not a territory.
    """
    root = settings.MAELIA_PROJECT_DIR / "includes"
    if not root.is_dir():
        return []
    names = [d.name for d in root.iterdir() if d.is_dir() and not d.name.startswith(".")]
    return sorted(names, key=lambda name: (name != settings.MAELIA_DEFAULT_TERRITORY, name))
