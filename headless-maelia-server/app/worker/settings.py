"""ARQ worker — consumes the run queue and drives GAMA.

`startup` checks that the worker sees GAMA and the shared volume at the same
paths as the API before accepting any run.
"""

import asyncio
import logging
import time
from typing import Any

from arq.connections import RedisSettings

from app.shared import health
from app.worker.tasks import run_simulation
from app.shared.config import settings

logging.basicConfig(level=settings.LOG_LEVEL)
log = logging.getLogger("maelia.worker")

# gama-headless exposes no healthcheck (the container is deliberately left
# untouched): give it time to open its socket.
STARTUP_WAIT_SECONDS = 120
STARTUP_RETRY_SECONDS = 5


async def ping(ctx: dict[str, Any]) -> dict[str, Any]:
    """Smoke task: check the dependencies from the worker side."""
    return await health.check_all()


async def startup(ctx: dict[str, Any]) -> None:
    """Wait until dependencies are actually reachable before accepting runs.

    A single probe at startup always fails: `gama-headless` takes about twenty
    seconds to open its socket, and postgis's `pg_isready` healthcheck turns
    green during initialisation, just before the server restarts and briefly
    refuses connections. Compose cannot cover either case (we do not want to
    touch the gama-headless container), so waiting is the worker's job.
    """
    deadline = time.monotonic() + STARTUP_WAIT_SECONDS
    attempt = 0
    report = await health.check_all()

    while report["status"] != "ok" and time.monotonic() < deadline:
        attempt += 1
        pending = [c["name"] for c in report["checks"] if c["status"] != "up"]
        log.info("dependencies not ready %s - retrying in %ss (attempt %d)",
                 pending, STARTUP_RETRY_SECONDS, attempt)
        await asyncio.sleep(STARTUP_RETRY_SECONDS)
        report = await health.check_all()

    for check in report["checks"]:
        level = logging.INFO if check["status"] == "up" else logging.ERROR
        log.log(level, "dependency %s: %s - %s", check["name"], check["status"], check["detail"])

    if report["status"] == "ok":
        log.info("worker ready - all dependencies reachable")
    else:
        # Do not block startup: ARQ stays available and tasks fail explicitly,
        # which reads better than a container stuck in a restart loop.
        log.error("worker started degraded after %ss of waiting", STARTUP_WAIT_SECONDS)


class WorkerSettings:
    functions = [ping, run_simulation]
    on_startup = startup
    redis_settings = RedisSettings.from_dsn(settings.REDIS_URL)
    max_jobs = settings.WORKER_MAX_JOBS
    # A 3-year MAELIA run takes tens of minutes: no short timeout.
    job_timeout = settings.GAMA_RUN_TIMEOUT
    keep_result = 3600
