"""SQLAlchemy adapters of the dataset context.

Holds three things the domain must not know about: how versions are stored, how
the row projection is kept, and how the mutable draft lives.
"""

import uuid

from sqlalchemy import delete as sql_delete, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.contexts.dataset.domain.models import (
    Dataset,
    DatasetVersion,
    Severity,
    ValidationIssue,
    VersionFile,
    VersionSource,
    VersionStatus,
)
from app.contexts.dataset.infrastructure.persistence import (
    BlobRow,
    DatasetDraftRecordRow,
    DatasetRow,
    DatasetVersionFileRow,
    DatasetVersionRecordRow,
    DatasetVersionRow,
    ValidationIssueRow,
)
from app.contexts.project.domain.models import FileStatus


def _version_to_domain(row: DatasetVersionRow) -> DatasetVersion:
    return DatasetVersion(
        id=row.id,
        dataset_id=row.dataset_id,
        number=row.number,
        status=VersionStatus(row.status),
        source=VersionSource(row.source),
        label=row.label,
        message=row.message,
        created_at=row.created_at,
        created_by=row.created_by,
        files=tuple(
            VersionFile(f.file_name, f.content_hash, f.size_bytes) for f in row.files
        ),
    )


def _to_domain(row: DatasetRow) -> Dataset:
    return Dataset(
        id=row.id,
        project_id=row.project_id,
        data_spec_id=row.data_spec_id,
        instance_key=row.instance_key,
        current_version_id=row.current_version_id,
        created_at=row.created_at,
        versions=tuple(_version_to_domain(v) for v in row.versions),
    )


_LOADED = (selectinload(DatasetRow.versions).selectinload(DatasetVersionRow.files),)


class SqlDatasetRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get(self, dataset_id: uuid.UUID) -> Dataset | None:
        result = await self._session.execute(
            select(DatasetRow).options(*_LOADED).where(DatasetRow.id == dataset_id)
        )
        row = result.scalar_one_or_none()
        return _to_domain(row) if row else None

    async def find(
        self, project_id: uuid.UUID, data_spec_id: str, instance_key: str | None
    ) -> Dataset | None:
        result = await self._session.execute(
            select(DatasetRow)
            .options(*_LOADED)
            .where(
                DatasetRow.project_id == project_id,
                DatasetRow.data_spec_id == data_spec_id,
                DatasetRow.instance_key.is_(None)
                if instance_key is None
                else DatasetRow.instance_key == instance_key,
            )
        )
        row = result.scalar_one_or_none()
        return _to_domain(row) if row else None

    async def list_for_project(self, project_id: uuid.UUID) -> list[Dataset]:
        result = await self._session.execute(
            select(DatasetRow)
            .options(*_LOADED)
            .where(DatasetRow.project_id == project_id)
            .order_by(DatasetRow.data_spec_id, DatasetRow.instance_key)
        )
        return [_to_domain(r) for r in result.scalars()]

    async def save(self, dataset: Dataset) -> Dataset:
        row = await self._session.get(DatasetRow, dataset.id)
        if row is None:
            row = DatasetRow(
                id=dataset.id,
                project_id=dataset.project_id,
                data_spec_id=dataset.data_spec_id,
                instance_key=dataset.instance_key,
            )
            self._session.add(row)
        row.current_version_id = dataset.current_version_id
        await self._session.flush()
        return await self.get(dataset.id)

    async def add_version(self, version: DatasetVersion) -> DatasetVersion:
        row = DatasetVersionRow(
            id=version.id,
            dataset_id=version.dataset_id,
            number=version.number,
            status=version.status.value,
            source=version.source.value,
            label=version.label,
            message=version.message,
            created_by=version.created_by,
        )
        self._session.add(row)
        await self._session.flush()

        for version_file in version.files:
            # The blob row may already exist: two versions can share content.
            if await self._session.get(BlobRow, version_file.content_hash) is None:
                from app.contexts.dataset.infrastructure.blob_store import object_key

                self._session.add(BlobRow(
                    content_hash=version_file.content_hash,
                    object_key=object_key(version_file.content_hash),
                    size_bytes=version_file.size_bytes,
                ))
                await self._session.flush()
            self._session.add(DatasetVersionFileRow(
                version_id=version.id,
                file_name=version_file.file_name,
                content_hash=version_file.content_hash,
                size_bytes=version_file.size_bytes,
            ))
        await self._session.flush()
        return version

    async def update_version_status(
        self, version_id: uuid.UUID, status: VersionStatus
    ) -> None:
        row = await self._session.get(DatasetVersionRow, version_id)
        if row is not None:
            row.status = status.value
            await self._session.flush()

    async def set_current_version(
        self, dataset_id: uuid.UUID, version_id: uuid.UUID | None
    ) -> None:
        row = await self._session.get(DatasetRow, dataset_id)
        if row is not None:
            row.current_version_id = version_id
            await self._session.flush()

    async def replace_issues(
        self, version_id: uuid.UUID, issues: list[ValidationIssue]
    ) -> None:
        await self._session.execute(
            sql_delete(ValidationIssueRow).where(ValidationIssueRow.version_id == version_id)
        )
        for issue in issues:
            self._session.add(ValidationIssueRow(
                version_id=version_id,
                row_index=issue.row_index,
                field_name=issue.field_name,
                severity=issue.severity.value,
                message=issue.message,
            ))
        await self._session.flush()

    async def issues_for(self, version_id: uuid.UUID) -> list[ValidationIssue]:
        result = await self._session.execute(
            select(ValidationIssueRow).where(ValidationIssueRow.version_id == version_id)
        )
        return [
            ValidationIssue(
                message=r.message,
                row_index=r.row_index,
                field_name=r.field_name,
                severity=Severity(r.severity),
            )
            for r in result.scalars()
        ]


class SqlRecordProjection:
    """Row projection of a version — derived, therefore always replaceable."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def replace(self, version_id: uuid.UUID, rows: list[dict[str, str]]) -> None:
        await self._session.execute(
            sql_delete(DatasetVersionRecordRow).where(
                DatasetVersionRecordRow.version_id == version_id
            )
        )
        for index, values in enumerate(rows):
            self._session.add(DatasetVersionRecordRow(
                version_id=version_id, row_index=index, values=values
            ))
        await self._session.flush()

    async def read(self, version_id: uuid.UUID) -> list[dict[str, str]]:
        result = await self._session.execute(
            select(DatasetVersionRecordRow)
            .where(DatasetVersionRecordRow.version_id == version_id)
            .order_by(DatasetVersionRecordRow.row_index)
        )
        return [r.values for r in result.scalars()]


class SqlDraftStore:
    """Mutable working copy, until publication freezes it into a version."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def read(self, dataset_id: uuid.UUID) -> list[dict[str, str]]:
        result = await self._session.execute(
            select(DatasetDraftRecordRow)
            .where(DatasetDraftRecordRow.dataset_id == dataset_id)
            .order_by(DatasetDraftRecordRow.row_index)
        )
        return [r.values for r in result.scalars()]

    async def replace(self, dataset_id: uuid.UUID, rows: list[dict[str, str]]) -> None:
        await self.clear(dataset_id)
        for index, values in enumerate(rows):
            self._session.add(DatasetDraftRecordRow(
                dataset_id=dataset_id, row_index=index, values=values
            ))
        await self._session.flush()

    async def clear(self, dataset_id: uuid.UUID) -> None:
        await self._session.execute(
            sql_delete(DatasetDraftRecordRow).where(
                DatasetDraftRecordRow.dataset_id == dataset_id
            )
        )
        await self._session.flush()


class SqlDatasetInventory:
    """Implements the project context's `DatasetInventoryPort`.

    Answers with a state, not with rows — which is what lets the project compute
    completion without knowing anything about dataset persistence.
    """

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def inventory(self, project_id: uuid.UUID) -> dict[str, dict[str, FileStatus]]:
        datasets = await SqlDatasetRepository(self._session).list_for_project(project_id)
        result: dict[str, dict[str, FileStatus]] = {}
        for dataset in datasets:
            key = dataset.instance_key or ""
            result.setdefault(dataset.data_spec_id, {})[key] = _file_status(dataset)
        return result


def _file_status(dataset: Dataset) -> FileStatus:
    """State of one file as the project sees it.

    A dataset with only draft or invalid versions is not usable for a run, so it
    must not count as supplied.
    """
    if not dataset.versions:
        return FileStatus.DRAFT
    if dataset.current_version is not None:
        return FileStatus.VALID
    if any(v.status is VersionStatus.INVALID for v in dataset.versions):
        return FileStatus.INVALID
    return FileStatus.DRAFT
