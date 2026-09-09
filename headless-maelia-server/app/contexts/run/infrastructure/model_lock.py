"""Serialise model compilation across concurrent runs.

GAMA cannot compile the same model twice at once: two simultaneous `load` calls
race on the Xtext resource registry and one of them dies with

    java.lang.IllegalStateException: A different resource with the URI
    'file:/opt/gama-platform/headless/__synthetic__N.gaml' was already registered.

The race window is the compilation itself (~35 s for MAELIA), not the simulation:
once loaded, several experiments run side by side without trouble — that has been
verified on three concurrent one-year runs.

So the lock covers `load` only. Runs still overlap; only their ramp-up queues.

The lock lives in Redis rather than in the process: `WORKER_MAX_JOBS` bounds
concurrency inside one worker, but scaling to several worker containers is an
explicit goal, and an `asyncio.Lock` would not span them.
"""

import asyncio
import logging
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from redis.asyncio import from_url

from app.shared.config import settings

log = logging.getLogger("maelia.run.lock")

LOCK_KEY = "maelia:gama:load"
POLL_SECONDS = 0.5

# Release only if we still hold the lock: after a TTL expiry the key may belong
# to another run, and deleting it blindly would let two loads overlap again.
RELEASE = """
if redis.call('get', KEYS[1]) == ARGV[1] then
    return redis.call('del', KEYS[1])
end
return 0
"""


@asynccontextmanager
async def model_load_lock(
    run_id: str,
    ttl_seconds: int | None = None,
    wait_seconds: int | None = None,
) -> AsyncIterator[None]:
    """Hold the compilation lock for the duration of the block.

    The TTL is a safety net: should a worker die mid-load, the lock frees itself
    instead of blocking every later run.
    """
    ttl = ttl_seconds or settings.GAMA_RUN_TIMEOUT
    deadline = asyncio.get_running_loop().time() + (wait_seconds or settings.GAMA_RUN_TIMEOUT)
    token = f"{run_id}:{uuid.uuid4()}"

    client = from_url(settings.REDIS_URL, decode_responses=True)
    acquired = False
    try:
        waited = False
        while True:
            acquired = bool(await client.set(LOCK_KEY, token, nx=True, ex=ttl))
            if acquired:
                break
            if asyncio.get_running_loop().time() > deadline:
                raise TimeoutError(
                    "un autre run compile le modèle depuis trop longtemps"
                )
            if not waited:
                log.info("run %s waits for the model compilation lock", run_id)
                waited = True
            # Bounded poll: yields control every half second, so the task stays
            # cancellable (see the "no unbounded wait loop" rule).
            await asyncio.sleep(POLL_SECONDS)

        yield
    finally:
        if acquired:
            try:
                await client.eval(RELEASE, 1, LOCK_KEY, token)
            except Exception as exc:  # best effort: the TTL will free it anyway
                log.warning("could not release the load lock for %s: %s", run_id, exc)
        await client.aclose()
