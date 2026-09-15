"""Test-bench routes — launching a control simulation.

Scope: run a registered launcher on headless GAMA, with no project and no
dataset. Used to validate a model before opening it to projects.
"""

import uuid
from typing import Annotated, Any

from arq.connections import ArqRedis, RedisSettings, create_pool
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.contexts.catalog.infrastructure.repository import (
    SqlCatalogRepository,
    SqlParameterRepository,
)
from app.contexts.dataset.application.use_cases import resolve_versions
from app.contexts.dataset.infrastructure.repository import (
    SqlDatasetInventory,
    SqlDatasetRepository,
)
from app.contexts.project.application import use_cases as project_use_cases
from app.contexts.project.infrastructure.repository import SqlProjectRepository
from app.contexts.run.infrastructure import redis_store as runs
from app.contexts.run.infrastructure.redis_store import RunStatus
from app.contexts.scenario.application import use_cases as scenario_use_cases
from app.contexts.scenario.domain.services import effective_parameters
from app.contexts.scenario.infrastructure.repository import SqlScenarioRepository
from app.shared.config import settings
from app.shared.database import get_session
from app.shared.errors import ConflictError

router = APIRouter(prefix="/api/v1/admin", tags=["test bench"])


class ModelInfo(BaseModel):
    id: str
    name: str
    path: str
    experiment: str
    description: str
    # Le jeu de données que ce launcher lit par défaut. Le banc d'essai n'a pas
    # de projet pour le lui dire : sans cette information il matérialiserait un
    # territoire et le modèle en chercherait un autre.
    territory: str


class LaunchRequest(BaseModel):
    model_id: str = Field(default="launcherTest")
    label: str | None = None
    # Pour essayer un launcher sur un autre jeu que le sien. Vide : celui que
    # le launcher déclare.
    territory: str | None = None
    # Deltas from the launcher defaults, in the format gama-server expects:
    # {"type": "int", "name": "nbAnneesSimulation", "value": 1}
    parameters: list[dict[str, Any]] = Field(default_factory=list)


def _launchers() -> dict[str, ModelInfo]:
    """Launchers exposed to the test bench.

    Hard-coded for now: this catalog will move to the database with the `model`
    context. Only launchers without an `output` block are headless-usable, and
    whose experiment carries an `until:` — hence the absence of launcherBase and
    launcherSasseme, and the presence of their headless twins.
    """
    main = settings.MAELIA_PROJECT_DIR / "models" / "main"
    return {
        "launcherTest": ModelInfo(
            id="launcherTest",
            name="MAELIA — launcher de test",
            path=str(main / "launcherTest.gaml"),
            experiment="test_maelia",
            description=(
                "Duplication de launcherBase adaptée au headless "
                "(until: simulationTerminee, sans bloc output)."
            ),
            territory="terrainTest",
        ),
        "launcherSassemeTest": ModelInfo(
            id="launcherSassemeTest",
            name="MAELIA — Sassème (Ferlo-Sine)",
            path=str(main / "launcherSassemeTest.gaml"),
            experiment="sasseme_maelia",
            description=(
                "La structure de launcherTest, les valeurs de launcherSasseme : "
                "les 149 paramètres du catalogue, réglés sur le territoire "
                "includes_sasseme, qu'il lit par défaut."
            ),
            territory="includes_sasseme",
        ),
    }


@router.get("/models", response_model=list[ModelInfo])
async def list_models() -> list[ModelInfo]:
    return list(_launchers().values())


@router.post("/runs", status_code=201)
async def launch(payload: LaunchRequest) -> dict[str, Any]:
    model = _launchers().get(payload.model_id)
    if model is None:
        raise HTTPException(status_code=404, detail=f"modèle inconnu : {payload.model_id}")

    # Le territoire du launcher voyage avec le run : le worker matérialise ce
    # que le modèle lira réellement, et un banc d'essai sans projet n'a pas à le
    # deviner.
    parameters = [
        p for p in payload.parameters
        if p.get("name") != "nomDecoupageZonePourLectureFichiers"
    ]
    parameters.append({
        "type": "string",
        "name": "nomDecoupageZonePourLectureFichiers",
        "value": payload.territory or model.territory,
    })

    run = await runs.create(
        model=model.path,
        experiment=model.experiment,
        parameters=parameters,
        label=payload.label or model.name,
    )

    # The run goes to the worker: the GAMA connection must outlive this HTTP
    # request by a long way.
    pool: ArqRedis = await create_pool(RedisSettings.from_dsn(settings.REDIS_URL))
    try:
        await pool.enqueue_job("run_simulation", run["id"])
    finally:
        await pool.aclose()

    return run


@router.get("/runs")
async def list_runs(limit: int = 50) -> list[dict[str, Any]]:
    return await runs.list_runs(limit=limit)


@router.get("/runs/{run_id}")
async def get_run(run_id: str) -> dict[str, Any]:
    run = await runs.get(run_id)
    if run is None:
        raise HTTPException(status_code=404, detail="run introuvable")
    return run


@router.post("/runs/{run_id}/cancel")
async def cancel_run(run_id: str) -> dict[str, Any]:
    """Demander l'arrêt d'une exécution.

    L'état passe à CANCELLED dans Redis ; c'est le signal que le worker guette
    entre deux messages de GAMA. Il envoie alors `stop` sur sa session ouverte,
    puis rend la main. L'arrêt n'est donc pas instantané — il prend le temps
    d'un aller-retour, quelques secondes — mais il libère réellement la JVM.

    Sans cela, un run abandonné continuait de tourner : il gardait sa mémoire,
    et plusieurs d'entre eux finissaient par faire tuer `gama-headless`.
    """
    run = await runs.get(run_id)
    if run is None:
        raise HTTPException(status_code=404, detail="run introuvable")
    if run["status"] in {RunStatus.FINISHED, RunStatus.FAILED, RunStatus.CANCELLED}:
        raise HTTPException(status_code=409, detail=f"run déjà {run['status']}")
    return await runs.update(run_id, status=RunStatus.CANCELLED)


# ── Project runs ────────────────────────────────────────────────────────────

project_router = APIRouter(prefix="/api/v1", tags=["runs"])


class ProjectRunRequest(BaseModel):
    scenario_id: uuid.UUID | None = None
    label: str | None = None
    model_id: str = "launcherTest"


@project_router.post("/projects/{project_id}/runs", status_code=201)
async def launch_project_run(
    session: Annotated[AsyncSession, Depends(get_session)],
    project_id: uuid.UUID,
    payload: ProjectRunRequest,
) -> dict[str, Any]:
    """Launch a run on a project, optionally through a scenario.

    Two things are frozen here, and only here:
      - the **parameters**, resolved from the scenario deltas;
      - the **data versions**, resolved for EVERY dataset of the project.

    Freezing at launch is what makes a result reproducible: publishing a newer
    version afterwards does not change what this run consumed.
    """
    model = _launchers().get(payload.model_id)
    if model is None:
        raise HTTPException(status_code=404, detail=f"modèle inconnu : {payload.model_id}")

    projects = SqlProjectRepository(session)
    project = await project_use_cases.get_project(projects, project_id)

    # Un projet tourne sur SES données : ce qui manque manquera vraiment. Mieux
    # vaut le dire ici qu'au bout de vingt minutes de simulation.
    _, completion = await project_use_cases.project_completion(
        projects, SqlCatalogRepository(session), SqlDatasetInventory(session), project_id
    )
    if completion.missing:
        raise ConflictError(
            f"{len(completion.missing)} entrée(s) obligatoire(s) manquante(s) : "
            + ", ".join(e.label for e in completion.missing[:5])
            + (" …" if len(completion.missing) > 5 else "")
        )

    scenario = None
    parameters: list[dict[str, Any]] = []
    if payload.scenario_id is not None:
        scenario = await scenario_use_cases.get_scenario(
            SqlScenarioRepository(session), payload.scenario_id
        )
        if scenario.project_id != project_id:
            raise HTTPException(
                status_code=409, detail="ce scénario appartient à un autre projet"
            )
        parameters = effective_parameters(
            scenario.parameter_values, await SqlParameterRepository(session).list_all()
        )

    # The territory comes from the project, never from the launcher default.
    parameters = [p for p in parameters if p["name"] != "nomDecoupageZonePourLectureFichiers"]
    parameters.append({
        "type": "string",
        "name": "nomDecoupageZonePourLectureFichiers",
        "value": project.territory,
    })

    resolved = await resolve_versions(
        SqlDatasetRepository(session), project_id, scenario.dataset_pins if scenario else None
    )

    run = await runs.create(
        model=model.path,
        experiment=model.experiment,
        parameters=parameters,
        label=payload.label or (scenario.name if scenario else project.name),
        project_id=str(project_id),
        scenario_id=str(payload.scenario_id) if payload.scenario_id else None,
        territory=project.territory,
        resolved_versions=resolved,
    )

    pool: ArqRedis = await create_pool(RedisSettings.from_dsn(settings.REDIS_URL))
    try:
        await pool.enqueue_job("run_simulation", run["id"])
    finally:
        await pool.aclose()

    return run


@project_router.get("/projects/{project_id}/runs")
async def list_project_runs(project_id: uuid.UUID, limit: int = 50) -> list[dict[str, Any]]:
    every = await runs.list_runs(limit=200)
    return [r for r in every if r.get("project_id") == str(project_id)][:limit]
