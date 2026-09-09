"""Application settings - read from the environment (see docker-compose.yml)."""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # ── Process role: "api" or "worker" (same image, different commands) ────
    APP_ROLE: str = "api"
    LOG_LEVEL: str = "INFO"
    CORS_ORIGINS: str = "http://localhost:5173"

    # ── Headless GAMA ───────────────────────────────────────────────────────
    GAMA_HOST: str = "gama-headless"
    GAMA_PORT: int = 6868
    GAMA_COMMAND_TIMEOUT: int = 300
    GAMA_RUN_TIMEOUT: int = 10800

    # ── MAELIA paths ────────────────────────────────────────────────────────
    # Identical in api, worker AND gama-headless: the invariant that lets a path
    # computed in Python be handed straight to GAMA.
    GAMA_MODELS_ROOT: Path = Path("/usr/lib/gama/workspace/gama-models")
    MAELIA_PROJECT_DIR: Path = Path(
        "/usr/lib/gama/workspace/gama-models/MAELIA_1.4.29_GAMA_2025-06"
    )
    MAELIA_ROOT_PATH: str = "/usr/lib/gama/workspace/gama-models/MAELIA_1.4.29_GAMA_2025-06/"
    MAELIA_MODEL_PATH: Path = Path(
        "/usr/lib/gama/workspace/gama-models/MAELIA_1.4.29_GAMA_2025-06"
        "/models/main/launcherBase.gaml"
    )
    MAELIA_EXPERIMENT_NAME: str = "simulationBase"
    # Default value of nomDecoupageZonePourLectureFichiers in launcherBase: tells
    # which territory to copy when the run does not override it.
    MAELIA_DEFAULT_TERRITORY: str = "terrainTest"
    # Outputs: written under <root>/models/main/log/<zone>_<name>_<timestamp>/
    MAELIA_OUTPUT_ROOT: Path = Path(
        "/usr/lib/gama/workspace/gama-models/MAELIA_1.4.29_GAMA_2025-06/models/main/log"
    )

    # ── Infrastructure ──────────────────────────────────────────────────────
    DATABASE_URL: str = "postgresql+asyncpg://maelia:maelia@db:5432/maelia"
    REDIS_URL: str = "redis://redis:6379/0"
    MINIO_ENDPOINT: str = "minio:9000"
    MINIO_ACCESS_KEY: str = "maelia"
    MINIO_SECRET_KEY: str = "maelia12345"
    MINIO_BUCKET: str = "maelia"
    MINIO_SECURE: bool = False

    WORKER_MAX_JOBS: int = 2

    @property
    def gama_ws_url(self) -> str:
        return f"ws://{self.GAMA_HOST}:{self.GAMA_PORT}"

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]

    @property
    def database_sync_url(self) -> str:
        """Synchronous DSN for Alembic (asyncpg at runtime, psycopg to migrate)."""
        return self.DATABASE_URL.replace("+asyncpg", "+psycopg")


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
