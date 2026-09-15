"""Project routes — SIMULATION domain."""

import uuid
from dataclasses import asdict
from datetime import datetime
from typing import Annotated, Any

from fastapi import APIRouter, Body, Depends
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.contexts.catalog.infrastructure.repository import SqlCatalogRepository
from app.contexts.project.application import use_cases
from app.contexts.project.domain.models import (
    DEFAULT_CONFIGURATION,
    Completion,
    FileStatus,
    Project,
)
from app.contexts.dataset.infrastructure.repository import SqlDatasetInventory
from app.contexts.project.infrastructure.repository import (
    SqlProjectRepository,
    available_territories,
)
from app.shared.database import get_session

router = APIRouter(prefix="/api/v1", tags=["projects"])

Session = Annotated[AsyncSession, Depends(get_session)]


def _projects(session: Session) -> SqlProjectRepository:
    return SqlProjectRepository(session)


Projects = Annotated[SqlProjectRepository, Depends(_projects)]


class ProjectIn(BaseModel):
    name: str
    # Non renseigné : le projet prend le jeu de référence. Le territoire n'est
    # pas un choix de l'utilisateur, c'est le socle sur lequel ses fichiers se
    # superposent.
    territory: str | None = None
    description: str | None = None
    modeling_config: dict[str, Any] = Field(default_factory=dict)


class ProjectPatch(BaseModel):
    name: str | None = None
    description: str | None = None


class ProjectOut(BaseModel):
    id: uuid.UUID
    name: str
    territory: str
    description: str | None
    modeling_config: dict[str, Any]
    created_at: datetime | None
    updated_at: datetime | None


class CompletionEntryOut(BaseModel):
    data_spec_id: str
    label: str
    module: str
    status: FileStatus
    instances: int
    multi_instance: bool
    required: bool


class CompletionOut(BaseModel):
    expected: int
    supplied: int
    ratio: float
    by_module: dict[str, dict[str, int]]
    entries: list[CompletionEntryOut]


def _render(project: Project) -> ProjectOut:
    return ProjectOut(**{
        k: getattr(project, k)
        for k in ("id", "name", "territory", "description", "modeling_config",
                  "created_at", "updated_at")
    })


def _render_completion(state: Completion) -> CompletionOut:
    return CompletionOut(
        expected=state.expected,
        supplied=state.supplied,
        ratio=state.ratio,
        by_module=state.by_module(),
        # `CompletionEntry` is a slots dataclass: no __dict__, so convert.
        entries=[CompletionEntryOut(**asdict(e)) for e in state.entries],
    )


@router.get("/territories", response_model=list[str])
async def territories() -> list[str]:
    """Territories shipped with the model, read from the shared volume."""
    return available_territories()


@router.get("/default-configuration")
async def default_configuration() -> dict[str, Any]:
    """Modelling settings of a fresh project (those of launcherBase.gaml)."""
    return DEFAULT_CONFIGURATION


@router.get("/projects", response_model=list[ProjectOut])
async def list_all(projects: Projects) -> list[ProjectOut]:
    return [_render(p) for p in await use_cases.list_projects(projects)]


@router.post("/projects", response_model=ProjectOut, status_code=201)
async def create(projects: Projects, session: Session, payload: ProjectIn) -> ProjectOut:
    project = await use_cases.create_project(
        projects,
        name=payload.name,
        territory=payload.territory,
        valid_territories=available_territories(),
        description=payload.description,
        modeling_config=payload.modeling_config,
    )
    await session.commit()
    return _render(project)


@router.get("/projects/{project_id}", response_model=ProjectOut)
async def get_one(projects: Projects, project_id: uuid.UUID) -> ProjectOut:
    return _render(await use_cases.get_project(projects, project_id))


@router.put("/projects/{project_id}", response_model=ProjectOut)
async def update(
    projects: Projects, session: Session, project_id: uuid.UUID, payload: ProjectPatch
) -> ProjectOut:
    project = await use_cases.update_project(
        projects, project_id, name=payload.name, description=payload.description
    )
    await session.commit()
    return _render(project)


@router.put("/projects/{project_id}/modeling-configuration", response_model=ProjectOut)
async def configure(
    projects: Projects,
    session: Session,
    project_id: uuid.UUID,
    config: Annotated[dict[str, Any], Body(default_factory=dict)],
) -> ProjectOut:
    project = await use_cases.update_configuration(projects, project_id, config)
    await session.commit()
    return _render(project)


@router.delete("/projects/{project_id}", status_code=204)
async def delete(projects: Projects, session: Session, project_id: uuid.UUID) -> None:
    await use_cases.delete_project(projects, project_id)
    await session.commit()


@router.get("/projects/{project_id}/completion", response_model=CompletionOut)
async def completion(
    projects: Projects, session: Session, project_id: uuid.UUID
) -> CompletionOut:
    """Files expected by the configuration, crossed with the data supplied."""
    _, state = await use_cases.project_completion(
        projects, SqlCatalogRepository(session), SqlDatasetInventory(session), project_id
    )
    return _render_completion(state)
