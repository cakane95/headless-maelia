"""Persistence foundation: async engine, session, declarative base.

No model here - each context declares its own in `infrastructure/persistence.py`,
all attached to the shared `Base` so Alembic sees them as one whole.
"""

from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.shared.config import settings


class Base(DeclarativeBase):
    """Declarative base shared by every context."""


engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    pool_pre_ping=True,   # a connection dropped by the DB is renewed, not propagated
)

session_factory = async_sessionmaker(engine, expire_on_commit=False, class_=AsyncSession)


async def get_session() -> AsyncIterator[AsyncSession]:
    """FastAPI dependency: one session per request, one transaction per use case.

    The transaction is opened by the use case, not here: this function only
    manages the connection lifecycle.
    """
    async with session_factory() as session:
        yield session
