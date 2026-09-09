"""Entry point of the headless-MAELIA API.

Assembly only: this module mounts the context routers and the tracking
WebSocket. No business rule here.
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware

from app.contexts.catalog.api import routes as catalog_routes
from app.contexts.catalog.infrastructure.repository import (
    SqlCatalogRepository,
    SqlParameterRepository,
)
from app.contexts.catalog.infrastructure.seed import apply_parameter_seed, apply_seed
from app.contexts.dataset.api import routes as dataset_routes
from app.contexts.project.api import routes as project_routes
from app.contexts.run.api import routes as run_routes
from app.contexts.scenario.api import routes as scenario_routes
from app.contexts.run.infrastructure import gama_probe, redis_store as runs
from app.shared import health
from app.shared.config import settings
from app.shared.database import session_factory
from app.shared.errors import install_error_handlers

logging.basicConfig(level=settings.LOG_LEVEL)
log = logging.getLogger("maelia.api")

@asynccontextmanager
async def lifespan(_: FastAPI):
    """Load the reference catalog at startup.

    Idempotent and non-destructive: customised specs (origin USER) are preserved.
    Best effort — an unmigrated database must not stop the API from starting, the
    health probe will report it.
    """
    try:
        async with session_factory() as session:
            files = await apply_seed(SqlCatalogRepository(session))
            parameters = await apply_parameter_seed(SqlParameterRepository(session))
            await session.commit()
        log.info("catalog loaded: files=%s parameters=%s", files, parameters)
    except Exception as exc:
        log.warning("catalog not loaded (%s) - see /api/v1/health/dependencies", exc)
    yield


app = FastAPI(
    lifespan=lifespan,
    title="headless-MAELIA API",
    version="0.1.0",
    description="Driving MAELIA simulations on headless GAMA.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

install_error_handlers(app)

app.include_router(catalog_routes.router)
app.include_router(dataset_routes.router)
app.include_router(project_routes.router)
app.include_router(run_routes.router)
app.include_router(run_routes.project_router)
app.include_router(scenario_routes.router)


@app.get("/health", tags=["health"])
async def liveness() -> dict[str, str]:
    """Liveness: the process answers. Used by the Docker HEALTHCHECK."""
    return {"status": "ok", "role": settings.APP_ROLE}


@app.get("/api/v1/health/dependencies", tags=["health"])
async def readiness() -> dict:
    """Readiness: state of postgres, redis, minio, gama-headless and shared volume."""
    return await health.check_all()


@app.get("/api/v1/gama/describe", tags=["gama"])
async def describe() -> dict:
    """Compile the MAELIA model on the GAMA side and return its experiments.

    End-to-end probe: socket, model visibility and GAML compilation. The first
    call is slow (full model compilation).
    """
    try:
        result = await gama_probe.describe_model()
    except TimeoutError as exc:
        raise HTTPException(
            status_code=504,
            detail=f"gama-headless n'a pas répondu en {settings.GAMA_COMMAND_TIMEOUT}s",
        ) from exc
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"{type(exc).__name__}: {exc}") from exc

    if result.get("type") != "CommandExecutedSuccessfully":
        raise HTTPException(status_code=502, detail=result)

    return {"model": str(settings.MAELIA_MODEL_PATH), "content": result.get("content")}


@app.websocket("/ws/runs/{run_id}")
async def run_events(websocket: WebSocket, run_id: str) -> None:
    """Live tracking of a run.

    The worker publishes to Redis and the API relays: this decoupling lets several
    clients follow the same run, and lets the API restart without interrupting
    the simulation.
    """
    await websocket.accept()

    run = await runs.get(run_id)
    if run is None:
        await websocket.close(code=4404, reason="run not found")
        return

    # Current state first, so a client joining mid-run does not stare at an empty
    # screen until the next event arrives.
    await websocket.send_json({"kind": "snapshot", "run": run})

    try:
        async for event in runs.subscribe(run_id):
            await websocket.send_text(event)
    except WebSocketDisconnect:
        pass
