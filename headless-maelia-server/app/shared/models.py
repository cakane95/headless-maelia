"""Gathering point for the ORM models.

Alembic must see every table to diff the schema. Rather than let `env.py` know
about each context, imports are centralised here: adding a context is adding a
line.
"""

from app.shared.database import Base  # noqa: F401  (re-exported for Alembic)

from app.contexts.catalog.infrastructure import persistence as _catalog  # noqa: F401
from app.contexts.dataset.infrastructure import persistence as _dataset  # noqa: F401
from app.contexts.project.infrastructure import persistence as _project  # noqa: F401
from app.contexts.result.infrastructure import persistence as _result  # noqa: F401
from app.contexts.run.infrastructure import persistence as _run  # noqa: F401
from app.contexts.scenario.infrastructure import persistence as _scenario  # noqa: F401
