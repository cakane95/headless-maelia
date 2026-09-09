"""Contexte de migration Alembic.

Deux points volontaires :
  - le DSN vient de `Settings`, jamais d'alembic.ini (une seule source de config) ;
  - on migre en **synchrone** (psycopg) alors que l'application tourne en async
    (asyncpg) : les migrations sont un script, pas un service.
"""

from logging.config import fileConfig

from alembic import context
from sqlalchemy import engine_from_config, pool

from app.shared.config import settings
from app.shared.models import Base  # importe tous les modèles des contextes

config = context.config
config.set_main_option("sqlalchemy.url", settings.database_sync_url)

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata

# PostGIS installe ses propres tables (tiger, topology, spatial_ref_sys). Sans ce
# filtre, l'autogénération les voit comme « à supprimer » et produit des DROP qui
# casseraient l'extension.
POSTGIS_SCHEMAS = {"tiger", "tiger_data", "topology"}
POSTGIS_TABLES = {"spatial_ref_sys", "geography_columns", "geometry_columns", "raster_columns",
                  "raster_overviews"}


def include_object(obj, name, type_, reflected, compare_to):
    if getattr(obj, "schema", None) in POSTGIS_SCHEMAS:
        return False
    if type_ == "table":
        # Une table réfléchie absente de nos métadonnées n'est pas à nous : on l'ignore
        # plutôt que de proposer sa suppression.
        return name in target_metadata.tables and name not in POSTGIS_TABLES
    return True


def run_migrations_offline() -> None:
    context.configure(
        url=settings.database_sync_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        include_object=include_object,
        include_schemas=False,
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            include_object=include_object,
            include_schemas=False,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
