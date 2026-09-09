"""Dataset context boundaries."""

import uuid
from typing import Protocol

from app.contexts.dataset.domain.models import (
    Dataset,
    DatasetVersion,
    ValidationIssue,
    VersionStatus,
)


class BlobStore(Protocol):
    """Content-addressed storage of version bytes.

    The only tier that is authoritative: what GAMA reads comes from here. The
    database only holds a derived projection.
    """

    async def put(self, payload: bytes) -> tuple[str, int]:
        """Store the bytes, return (content_hash, size). Idempotent by digest."""
        ...

    async def get(self, content_hash: str) -> bytes: ...

    async def exists(self, content_hash: str) -> bool: ...


class DatasetRepository(Protocol):
    async def get(self, dataset_id: uuid.UUID) -> Dataset | None: ...

    async def find(
        self, project_id: uuid.UUID, data_spec_id: str, instance_key: str | None
    ) -> Dataset | None: ...

    async def list_for_project(self, project_id: uuid.UUID) -> list[Dataset]: ...

    async def save(self, dataset: Dataset) -> Dataset: ...

    async def add_version(self, version: DatasetVersion) -> DatasetVersion: ...

    async def update_version_status(
        self, version_id: uuid.UUID, status: VersionStatus
    ) -> None: ...

    async def set_current_version(
        self, dataset_id: uuid.UUID, version_id: uuid.UUID | None
    ) -> None: ...

    async def replace_issues(
        self, version_id: uuid.UUID, issues: list[ValidationIssue]
    ) -> None: ...

    async def issues_for(self, version_id: uuid.UUID) -> list[ValidationIssue]: ...


class RecordProjection(Protocol):
    """Row projection of a version — derived from the blob, therefore rebuildable.

    Powers the grid view and the diff between two versions. Losing it costs
    nothing: it can be recomputed from the bytes.
    """

    async def replace(self, version_id: uuid.UUID, rows: list[dict[str, str]]) -> None: ...

    async def read(self, version_id: uuid.UUID) -> list[dict[str, str]]: ...


class DraftStore(Protocol):
    """Mutable working copy, until publication freezes it into a version."""

    async def read(self, dataset_id: uuid.UUID) -> list[dict[str, str]]: ...

    async def replace(self, dataset_id: uuid.UUID, rows: list[dict[str, str]]) -> None: ...

    async def clear(self, dataset_id: uuid.UUID) -> None: ...
