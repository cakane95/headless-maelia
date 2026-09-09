"""Catalog context boundaries.

One port per genuinely substitutable external dependency — here, persistence.
Nothing more: we do not abstract what has a single implementation and no need to
be tested in isolation.
"""

from typing import Protocol

from app.contexts.catalog.domain.models import DataSpec


class CatalogRepository(Protocol):
    async def list_all(self) -> list[DataSpec]: ...

    async def get(self, spec_id: str) -> DataSpec | None: ...

    async def upsert(self, spec: DataSpec) -> DataSpec: ...

    async def delete(self, spec_id: str) -> bool: ...

    async def count(self) -> int: ...
