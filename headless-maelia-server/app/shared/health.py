"""Dependency readiness probes (db, redis, minio, gama, shared volume)."""

import asyncio
from typing import Any

from app.shared.config import settings


async def _check(name: str, coro) -> dict[str, Any]:
    try:
        detail = await coro
        return {"name": name, "status": "up", "detail": detail}
    except Exception as exc:  # a probe reports, it never propagates
        return {"name": name, "status": "down", "detail": f"{type(exc).__name__}: {exc}"}


async def _postgres() -> str:
    import asyncpg

    dsn = settings.DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
    conn = await asyncpg.connect(dsn, timeout=5)
    try:
        version = await conn.fetchval("select version()")
        postgis = await conn.fetchval(
            "select exists(select 1 from pg_extension where extname = 'postgis')"
        )
        revision = await conn.fetchval(
            "select version_num from alembic_version limit 1"
        ) if await conn.fetchval(
            "select to_regclass('public.alembic_version') is not null"
        ) else None
        migrations = f" | migrations={revision}" if revision else " | migrations=not applied"
        return f"{version.split(',')[0]} | postgis={postgis}{migrations}"
    finally:
        await conn.close()


async def _redis() -> str:
    from redis.asyncio import from_url

    client = from_url(settings.REDIS_URL)
    try:
        await client.ping()
        return "PONG"
    finally:
        await client.aclose()


async def _minio() -> str:
    from minio import Minio

    def _call() -> str:
        client = Minio(
            settings.MINIO_ENDPOINT,
            access_key=settings.MINIO_ACCESS_KEY,
            secret_key=settings.MINIO_SECRET_KEY,
            secure=settings.MINIO_SECURE,
        )
        exists = client.bucket_exists(settings.MINIO_BUCKET)
        return f"bucket '{settings.MINIO_BUCKET}' exists={exists}"

    return await asyncio.to_thread(_call)


async def _gama_socket() -> str:
    _, writer = await asyncio.wait_for(
        asyncio.open_connection(settings.GAMA_HOST, settings.GAMA_PORT), timeout=5
    )
    writer.close()
    await writer.wait_closed()
    return f"{settings.GAMA_HOST}:{settings.GAMA_PORT} accessible"


async def _shared_volume() -> str:
    """Check the path invariant: the model must be visible AND writable.

    This was failure number one on the previous platform - a mount that differs
    between api/worker and gama-headless yields baffling errors on the GAMA side.
    """
    model = settings.MAELIA_MODEL_PATH
    if not model.is_file():
        raise FileNotFoundError(f"model not found at the shared path: {model}")

    project = settings.MAELIA_PROJECT_DIR
    if not (project / ".project").is_file():
        raise FileNotFoundError(
            f"{project} is not a GAMA project (.project missing) - "
            "GAMA will refuse to load the model"
        )

    probe = project / ".write-probe"
    probe.write_text("ok", encoding="utf-8")
    probe.unlink()

    return f"model readable, valid GAMA project, write OK ({project})"


async def check_all() -> dict[str, Any]:
    checks = await asyncio.gather(
        _check("postgres", _postgres()),
        _check("redis", _redis()),
        _check("minio", _minio()),
        _check("gama-headless", _gama_socket()),
        _check("shared-volume", _shared_volume()),
    )
    healthy = all(c["status"] == "up" for c in checks)
    return {"status": "ok" if healthy else "degraded", "checks": checks}
