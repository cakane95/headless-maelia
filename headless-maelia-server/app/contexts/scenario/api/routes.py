"""Scenario routes — SIMULATION domain.

A scenario carries what makes a run different: the parameter deltas and the
pinned data versions.
"""

import uuid
from datetime import datetime
from typing import Annotated, Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.contexts.catalog.infrastructure.repository import (
    SqlCatalogRepository,
    SqlParameterRepository,
)
from app.contexts.dataset.infrastructure.blob_store import MinioBlobStore
from app.contexts.dataset.infrastructure.repository import SqlDatasetRepository
from app.contexts.scenario.application import options as parameter_options
from app.contexts.scenario.application import use_cases
from app.contexts.scenario.domain.models import Scenario
from app.contexts.scenario.domain.services import effective_parameters, grouped
from app.contexts.scenario.infrastructure.repository import SqlScenarioRepository
from app.shared.database import get_session
from app.shared.errors import NotFoundError

router = APIRouter(prefix="/api/v1", tags=["scenarios"])

Session = Annotated[AsyncSession, Depends(get_session)]


def _scenarios(session: Session) -> SqlScenarioRepository:
    return SqlScenarioRepository(session)


def _parameters(session: Session) -> SqlParameterRepository:
    return SqlParameterRepository(session)


def _datasets(session: Session) -> SqlDatasetRepository:
    return SqlDatasetRepository(session)


Scenarios = Annotated[SqlScenarioRepository, Depends(_scenarios)]
Parameters = Annotated[SqlParameterRepository, Depends(_parameters)]
Datasets = Annotated[SqlDatasetRepository, Depends(_datasets)]


class ParameterSpecOut(BaseModel):
    name: str
    label: str
    group: str
    type: str
    default: Any = None
    allowed_values: list[str] = Field(default_factory=list)
    system: bool
    editable: bool
    # '<data_spec_id>#<champ>' : les valeurs acceptables vivent dans un fichier.
    options_from: str | None = None


class OptionsOut(BaseModel):
    parameter: str
    values: list[str]
    data_spec_id: str | None = None
    field: str | None = None
    available: bool
    message: str | None = None
    truncated: bool


class ScenarioIn(BaseModel):
    name: str
    description: str | None = None
    parameter_values: dict[str, Any] = Field(default_factory=dict)
    dataset_pins: dict[str, str] = Field(default_factory=dict)


class ScenarioPatch(BaseModel):
    name: str | None = None
    description: str | None = None
    parameter_values: dict[str, Any] | None = None
    dataset_pins: dict[str, str] | None = None


class ScenarioOut(BaseModel):
    id: uuid.UUID
    project_id: uuid.UUID
    name: str
    description: str | None
    parameter_values: dict[str, Any]
    dataset_pins: dict[str, str]
    created_at: datetime | None
    updated_at: datetime | None


def _render(scenario: Scenario) -> ScenarioOut:
    return ScenarioOut(**{
        k: getattr(scenario, k)
        for k in ("id", "project_id", "name", "description", "parameter_values",
                  "dataset_pins", "created_at", "updated_at")
    })


# ── Parameter catalog ───────────────────────────────────────────────────────

@router.get("/parameters", response_model=list[ParameterSpecOut])
async def list_parameters(parameters: Parameters) -> list[ParameterSpecOut]:
    """Every parameter the launcher exposes, system ones included."""
    return [
        ParameterSpecOut(
            name=p.name, label=p.label, group=p.group, type=p.type.value,
            default=p.default, allowed_values=list(p.allowed_values),
            system=p.system, editable=p.editable, options_from=p.options_from,
        )
        for p in await parameters.list_all()
    ]


@router.get("/parameters/groups")
async def parameter_groups(parameters: Parameters) -> dict[str, list[str]]:
    """Parameter names by launcher section, for the editing screen."""
    return {
        group: [s.name for s in specs]
        for group, specs in grouped(await parameters.list_all()).items()
    }


@router.get(
    "/projects/{project_id}/parameters/{name}/options", response_model=OptionsOut
)
async def options(
    parameters: Parameters,
    datasets: Datasets,
    session: Session,
    project_id: uuid.UUID,
    name: str,
) -> OptionsOut:
    """Values this project allows for a parameter.

    Read from the project's own data — the identifiers of *its* farms, not the
    model's samples. A project that has not loaded the file yet gets
    `available: false` and keeps a free field, rather than an empty list that
    would look like « no choice ».
    """
    spec = await parameters.get(name)
    if spec is None:
        raise NotFoundError(f"paramètre inconnu : {name}")

    found = await parameter_options.parameter_options(
        spec, SqlCatalogRepository(session), datasets, MinioBlobStore(), project_id
    )
    return OptionsOut(
        parameter=found.parameter,
        values=list(found.values),
        data_spec_id=found.data_spec_id,
        field=found.field,
        available=found.available,
        message=found.message,
        truncated=found.truncated,
    )


# ── Scenarios ───────────────────────────────────────────────────────────────

@router.get("/projects/{project_id}/scenarios", response_model=list[ScenarioOut])
async def list_for_project(scenarios: Scenarios, project_id: uuid.UUID) -> list[ScenarioOut]:
    return [_render(s) for s in await use_cases.list_scenarios(scenarios, project_id)]


@router.post("/projects/{project_id}/scenarios", response_model=ScenarioOut, status_code=201)
async def create(
    scenarios: Scenarios,
    parameters: Parameters,
    datasets: Datasets,
    session: Session,
    project_id: uuid.UUID,
    payload: ScenarioIn,
) -> ScenarioOut:
    scenario = await use_cases.create_scenario(
        scenarios, parameters, datasets, project_id,
        name=payload.name, description=payload.description,
        parameter_values=payload.parameter_values, dataset_pins=payload.dataset_pins,
    )
    await session.commit()
    return _render(scenario)


@router.get("/scenarios/{scenario_id}", response_model=ScenarioOut)
async def get_one(scenarios: Scenarios, scenario_id: uuid.UUID) -> ScenarioOut:
    return _render(await use_cases.get_scenario(scenarios, scenario_id))


@router.put("/scenarios/{scenario_id}", response_model=ScenarioOut)
async def update(
    scenarios: Scenarios,
    parameters: Parameters,
    datasets: Datasets,
    session: Session,
    scenario_id: uuid.UUID,
    payload: ScenarioPatch,
) -> ScenarioOut:
    scenario = await use_cases.update_scenario(
        scenarios, parameters, datasets, scenario_id,
        name=payload.name, description=payload.description,
        parameter_values=payload.parameter_values, dataset_pins=payload.dataset_pins,
    )
    await session.commit()
    return _render(scenario)


@router.delete("/scenarios/{scenario_id}", status_code=204)
async def delete(scenarios: Scenarios, session: Session, scenario_id: uuid.UUID) -> None:
    await use_cases.delete_scenario(scenarios, scenario_id)
    await session.commit()


@router.get("/scenarios/{scenario_id}/gama-parameters")
async def gama_parameters(
    scenarios: Scenarios, parameters: Parameters, scenario_id: uuid.UUID
) -> list[dict[str, Any]]:
    """The payload this scenario would send at `load`.

    Only the deltas travel: an unset parameter keeps the launcher's own default,
    which is what makes a scenario survive a model upgrade.
    """
    scenario = await use_cases.get_scenario(scenarios, scenario_id)
    return effective_parameters(scenario.parameter_values, await parameters.list_all())
