"""ARQ tasks — running a GAMA simulation end to end."""

import asyncio
import logging
import re
import time
from pathlib import Path
from typing import Any

from app.contexts.dataset.application import materialize as includes
from app.contexts.run.infrastructure import redis_store as runs
from app.contexts.run.infrastructure.gama_session import (
    GamaError,
    GamaSession,
    RunCancelled,
)
from app.contexts.run.infrastructure.model_lock import model_load_lock
from app.contexts.run.infrastructure.redis_store import RunStatus
from app.shared.config import settings

log = logging.getLogger("maelia.worker.run")

# The launcher announces its output directory on the console at init time.
OUTPUT_DIR_MARKER = "cheminRelatifDuDossierDeSortieDeSimulation:"
# The model logs one line per simulated day:
#   -----------------Sa 31/12/2019 (j 365) (152) -----------------
# That is the only usable progress signal during a run (it never writes "cycle N").
DAY_RE = re.compile(r"(\d{2}/\d{2}/\d{4})\s*\(j\s*(\d+)\)")


def resolve_territory(user_parameters: list[dict[str, Any]]) -> str:
    """Effective territory of the run: the requested one, else the launcher's."""
    for parameter in user_parameters:
        if parameter.get("name") == "nomDecoupageZonePourLectureFichiers":
            value = str(parameter.get("value") or "").strip()
            if value:
                return value
    return settings.MAELIA_DEFAULT_TERRITORY


def system_parameters(run_id: str, includes_path: str) -> list[dict[str, Any]]:
    """Parameters imposed by the platform; they win over the scenario's.

    The two that make concurrency possible:
      - `idSimulationAPI`: makes `majChemins` in main.gaml write outputs to
        models/main/log/<runId> — a deterministic, per-run directory, so no
        write collision;
      - `cheminModeleVersDonnees`: points at the run's working copy, because
        MAELIA rewrites some of its own input files
        (see contexts/dataset/application/materialize.py).
    """
    return [
        {"type": "bool", "name": "executerSurCluster", "value": False},
        {"type": "string", "name": "cheminRacineMaelia", "value": settings.MAELIA_ROOT_PATH},
        {"type": "string", "name": "cheminModeleVersDonnees", "value": includes_path},
        {"type": "string", "name": "idSimulationAPI", "value": run_id},
    ]


def _merge_parameters(
    user: list[dict[str, Any]], run_id: str, includes_path: str
) -> list[dict[str, Any]]:
    """User parameters, then system parameters (which override duplicates)."""
    system = system_parameters(run_id, includes_path)
    reserved = {p["name"] for p in system}
    return [p for p in user if p.get("name") not in reserved] + system


async def run_simulation(ctx: dict[str, Any], run_id: str) -> dict[str, Any]:
    """Load, run and harvest a simulation. One task = one run = one socket."""
    run = await runs.get(run_id)
    if run is None:
        raise RuntimeError(f"unknown run: {run_id}")

    state: dict[str, Any] = {"output_dir": None, "cycle": None, "day": None, "date": None}

    async def on_event(message: dict[str, Any]) -> None:
        """Relay the GAMA stream to Redis and extract what matters."""
        content = message.get("content")
        text = content.get("message") if isinstance(content, dict) else content
        if not isinstance(text, str) or not text.strip():
            return

        if OUTPUT_DIR_MARKER in text:
            state["output_dir"] = text.split(OUTPUT_DIR_MARKER, 1)[1].strip()

        found = DAY_RE.search(text)
        if found:
            state["date"], state["day"] = found.group(1), int(found.group(2))

        await runs.append_log(
            run_id, text.rstrip(), cycle=state["day"], current_date=state["date"]
        )

    async def arret_demande() -> bool:
        """L'utilisateur a-t-il demandé l'arrêt ?

        L'état vit dans Redis, écrit par l'API : c'est le seul canal que le
        worker et l'API partagent déjà. Une lecture toutes les deux secondes
        pendant que la simulation parle coûte moins qu'un run qui continue
        d'occuper la JVM après qu'on l'a abandonné.
        """
        courant = await runs.get(run_id)
        return bool(courant and courant["status"] == RunStatus.CANCELLED)

    user_parameters = run.get("parameters") or []
    territory = resolve_territory(user_parameters)

    await runs.update(
        run_id,
        status=RunStatus.RUNNING,
        started_at=time.time(),
        error=None,
        territory=territory,
    )

    try:
        # Working copy BEFORE the load: a run must never read — nor rewrite —
        # the shared baseline, otherwise two concurrent runs corrupt each other.
        overlays = await _project_overlays(run)
        # Un run de projet part de SES fichiers, et de rien d'autre. Le banc
        # d'essai, lui, copie le jeu livré : c'est sa raison d'être.
        from_project = bool(run.get("project_id"))
        await runs.append_log(
            run_id,
            f"[platform] materialising includes ({territory}, "
            f"{len(overlays)} file(s)"
            f"{', projet seul' if from_project else ', jeu livré'})...",
        )
        includes_path = await asyncio.to_thread(
            includes.materialize, run_id, territory, overlays, not from_project
        )

        async with GamaSession(on_event=on_event) as session:
            # GAMA cannot compile the same model twice at once (Xtext resource
            # clash). The lock covers the load only: simulations still overlap.
            await runs.append_log(run_id, "[platform] compiling model...")
            async with model_load_lock(run_id):
                await session.load(
                    model=run["model"],
                    experiment=run["experiment"],
                    parameters=_merge_parameters(user_parameters, run_id, includes_path),
                    until="simulationTerminee",
                )
            await runs.append_log(
                run_id, f"[platform] model loaded (exp_id={session.exp_id}), starting..."
            )

            await session.play()
            try:
                await session.wait_for_end(cancelled=arret_demande)
            except RunCancelled:
                # `stop` doit partir TANT QUE le socket est ouvert : en sortant
                # du `async with`, la session est fermee et GAMA detruit la
                # simulation sans qu'on ait rendu la main proprement.
                await runs.append_log(
                    run_id, "[platform] arrêt demandé, envoi de stop à GAMA"
                )
                await session.stop()
                raise

            # The run has ended: read the final cycle from GAMA, which is more
            # reliable than parsing the console.
            try:
                state["cycle"] = int(await session.expression("cycle"))
            except Exception as exc:
                log.warning("final cycle unavailable for %s: %s", run_id, exc)

    except RunCancelled:
        await runs.append_log(run_id, "[platform] arrêté à la demande")
        await runs.update(run_id, status=RunStatus.CANCELLED, ended_at=time.time())
        return {"status": RunStatus.CANCELLED}
    except (GamaError, TimeoutError, OSError) as exc:
        await runs.append_log(run_id, f"[platform] FAILED: {exc}")
        await runs.update(
            run_id, status=RunStatus.FAILED, error=str(exc), ended_at=time.time()
        )
        return {"status": RunStatus.FAILED, "error": str(exc)}
    finally:
        # Outputs live elsewhere (models/main/log/<runId>): the working copy is
        # useless once the run is over, whatever the outcome.
        await asyncio.to_thread(includes.cleanup, run_id)

    output_dir, artifacts = _collect_outputs(run_id, state["output_dir"])
    await runs.append_log(
        run_id, f"[platform] finished - {len(artifacts)} output file(s)"
    )
    await runs.update(
        run_id,
        status=RunStatus.FINISHED,
        cycle=state["cycle"],
        current_date=state["date"],
        output_dir=output_dir,
        artifacts=artifacts,
        ended_at=time.time(),
    )
    return {"status": RunStatus.FINISHED, "artifacts": len(artifacts)}


async def _project_overlays(run: dict[str, Any]) -> list[includes.OverlayFile]:
    """Files of the project that override the baseline, per the frozen resolution.

    A test-bench run carries no resolution: it runs on the bare territory, which
    is exactly what validating a model requires.
    """
    resolved = run.get("resolved_versions") or {}
    if not resolved:
        return []

    # Imported here, not at module level: the worker must be able to run a
    # test-bench simulation even if the database is unreachable.
    from app.contexts.catalog.infrastructure.repository import SqlCatalogRepository
    from app.contexts.dataset.application.use_cases import build_overlays
    from app.contexts.dataset.infrastructure.blob_store import MinioBlobStore
    from app.contexts.dataset.infrastructure.repository import SqlDatasetRepository
    from app.shared.database import session_factory

    async with session_factory() as session:
        return await build_overlays(
            SqlDatasetRepository(session),
            SqlCatalogRepository(session),
            MinioBlobStore(),
            resolved,
        )


def _collect_outputs(run_id: str, announced: str | None) -> tuple[str | None, list[dict[str, Any]]]:
    """Locate the output directory and list its files.

    `idSimulationAPI` makes the path deterministic; the path announced on the
    console is a fallback should the model change convention.
    """
    candidates = [settings.MAELIA_OUTPUT_ROOT / run_id]
    if announced:
        candidates.append(Path(announced))

    directory = next((c for c in candidates if c.is_dir()), None)
    if directory is None:
        log.warning("no output directory found for %s (tried: %s)", run_id, candidates)
        return None, []

    artifacts = [
        {"name": f.name, "size": f.stat().st_size, "path": str(f)}
        for f in sorted(directory.rglob("*"))
        if f.is_file()
    ]
    return str(directory), artifacts
