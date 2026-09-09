"""Run state storage and broadcast — Redis adapter.

Temporary: to be replaced by a SQLAlchemy repository. This module's surface is
deliberately narrow so the switch touches neither the worker nor the routes.
"""

import json
import time
import uuid
from collections.abc import AsyncIterator
from enum import StrEnum
from typing import Any

from redis.asyncio import Redis, from_url

from app.shared.config import settings

RUN_KEY = "maelia:run:{run_id}"
RUN_INDEX = "maelia:runs"          # ids, most recent first
RUN_CHANNEL = "maelia:run:{run_id}:events"
MAX_LOG_LINES = 500                # bounds a run's in-memory size


class RunStatus(StrEnum):
    PENDING = "PENDING"
    RUNNING = "RUNNING"
    FINISHED = "FINISHED"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"


def _redis() -> Redis:
    return from_url(settings.REDIS_URL, decode_responses=True)


async def create(
    model: str,
    experiment: str,
    parameters: list[dict[str, Any]],
    label: str | None = None,
    project_id: str | None = None,
    scenario_id: str | None = None,
    territory: str | None = None,
    resolved_versions: dict[str, str] | None = None,
) -> dict[str, Any]:
    run = {
        "id": str(uuid.uuid4()),
        "label": label or "Test simulation",
        "model": model,
        "experiment": experiment,
        "parameters": parameters,
        "project_id": project_id,
        "scenario_id": scenario_id,
        # Frozen at launch: the run keeps using these versions even after newer
        # ones are published. That is what makes replaying a scenario meaningful.
        "resolved_versions": resolved_versions or {},
        "status": RunStatus.PENDING,
        "cycle": None,
        "current_date": None,
        "territory": territory,
        "error": None,
        "output_dir": None,
        "artifacts": [],
        "logs": [],
        "created_at": time.time(),
        "started_at": None,
        "ended_at": None,
    }
    client = _redis()
    try:
        await client.set(RUN_KEY.format(run_id=run["id"]), json.dumps(run))
        await client.lpush(RUN_INDEX, run["id"])
    finally:
        await client.aclose()
    return run


async def get(run_id: str) -> dict[str, Any] | None:
    client = _redis()
    try:
        raw = await client.get(RUN_KEY.format(run_id=run_id))
    finally:
        await client.aclose()
    return json.loads(raw) if raw else None


async def list_runs(limit: int = 50) -> list[dict[str, Any]]:
    client = _redis()
    try:
        ids = await client.lrange(RUN_INDEX, 0, limit - 1)
        if not ids:
            return []
        raws = await client.mget([RUN_KEY.format(run_id=i) for i in ids])
    finally:
        await client.aclose()

    runs = [json.loads(r) for r in raws if r]
    # Logs bloat the list without informing it: they stay on the detail view.
    for run in runs:
        run.pop("logs", None)
    return runs


async def update(run_id: str, **fields: Any) -> dict[str, Any] | None:
    """Write fields and broadcast the new state to WebSocket subscribers."""
    client = _redis()
    try:
        key = RUN_KEY.format(run_id=run_id)
        raw = await client.get(key)
        if not raw:
            return None
        run = json.loads(raw)
        run.update(fields)
        await client.set(key, json.dumps(run))
        await client.publish(
            RUN_CHANNEL.format(run_id=run_id),
            json.dumps({"kind": "state", "run": {k: v for k, v in run.items() if k != "logs"}}),
        )
    finally:
        await client.aclose()
    return run


async def append_log(
    run_id: str,
    line: str,
    cycle: int | None = None,
    current_date: str | None = None,
) -> None:
    """Append a console line and broadcast it immediately.

    Broadcasting happens before the write so live tracking stays responsive even
    when the run is noisy.
    """
    client = _redis()
    try:
        await client.publish(
            RUN_CHANNEL.format(run_id=run_id),
            json.dumps(
                {"kind": "log", "line": line, "cycle": cycle, "current_date": current_date}
            ),
        )
        key = RUN_KEY.format(run_id=run_id)
        raw = await client.get(key)
        if not raw:
            return
        run = json.loads(raw)
        run["logs"] = (run.get("logs") or [])[-(MAX_LOG_LINES - 1) :] + [line]
        if cycle is not None:
            run["cycle"] = cycle
        if current_date is not None:
            run["current_date"] = current_date
        await client.set(key, json.dumps(run))
    finally:
        await client.aclose()


async def subscribe(run_id: str) -> AsyncIterator[str]:
    """Stream of a run's events, relayed over WebSocket to the front end.

    We poll with a `timeout` rather than use `pubsub.listen()`: `listen()` blocks
    forever, so a tab left open used to prevent the API from shutting down
    (uvicorn waits for tasks to finish, --reload included). This loop yields every
    second and therefore stays cancellable.
    """
    channel = RUN_CHANNEL.format(run_id=run_id)
    client = _redis()
    pubsub = client.pubsub()
    await pubsub.subscribe(channel)
    try:
        while True:
            message = await pubsub.get_message(ignore_subscribe_messages=True, timeout=1.0)
            if message is not None:
                yield message["data"]
    finally:
        await pubsub.unsubscribe(channel)
        await pubsub.aclose()
        await client.aclose()
