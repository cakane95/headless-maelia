"""Dataset routes — SIMULATION domain.

Two ways to create a version, and only two:
  - `POST .../versions`         upload; the bytes are stored as received;
  - `POST .../draft/publish`    edit; the rows are serialised once, then frozen.
"""

import uuid
import zipfile
from datetime import datetime
from io import BytesIO
from typing import Annotated, Any

from fastapi import APIRouter, Depends, File, Form, UploadFile
from fastapi.responses import Response
from pydantic import BaseModel, ConfigDict, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.contexts.catalog.infrastructure.repository import SqlCatalogRepository
from app.contexts.dataset.application import use_cases
from app.contexts.dataset.domain.models import (
    Dataset,
    DatasetVersion,
    Severity,
    ValidationIssue,
    VersionSource,
    VersionStatus,
)
from app.contexts.dataset.infrastructure.blob_store import MinioBlobStore
from app.contexts.dataset.infrastructure.repository import (
    SqlDatasetRepository,
    SqlDraftStore,
    SqlRecordProjection,
)
from app.shared.database import get_session

router = APIRouter(prefix="/api/v1", tags=["datasets"])

Session = Annotated[AsyncSession, Depends(get_session)]


def _datasets(session: Session) -> SqlDatasetRepository:
    return SqlDatasetRepository(session)


Datasets = Annotated[SqlDatasetRepository, Depends(_datasets)]


def _catalog(session: Session) -> SqlCatalogRepository:
    return SqlCatalogRepository(session)


Catalog = Annotated[SqlCatalogRepository, Depends(_catalog)]


def _blobs() -> MinioBlobStore:
    return MinioBlobStore()


Blobs = Annotated[MinioBlobStore, Depends(_blobs)]


# ── Schemas ─────────────────────────────────────────────────────────────────

class IssueOut(BaseModel):
    message: str
    row_index: int | None = None
    field_name: str | None = None
    severity: Severity = Severity.ERROR


class VersionFileOut(BaseModel):
    file_name: str
    content_hash: str
    size_bytes: int


class VersionOut(BaseModel):
    id: uuid.UUID
    number: int
    status: VersionStatus
    source: VersionSource
    label: str | None
    message: str | None
    display_name: str
    created_at: datetime | None
    created_by: str | None
    files: list[VersionFileOut]


class DatasetOut(BaseModel):
    id: uuid.UUID
    project_id: uuid.UUID
    data_spec_id: str
    instance_key: str | None
    current_version_id: uuid.UUID | None
    versions: list[VersionOut]


class UploadOut(BaseModel):
    dataset: DatasetOut
    version: VersionOut
    issues: list[IssueOut]


class DraftIn(BaseModel):
    # An unknown field must not pass: sending `records` instead of `rows` used to
    # be accepted silently and wiped the draft.
    model_config = ConfigDict(extra="forbid")

    rows: list[dict[str, Any]] = Field(default_factory=list)


class PublishIn(BaseModel):
    label: str | None = None
    message: str | None = None


class ResolveIn(BaseModel):
    pins: dict[str, str] = Field(default_factory=dict)


def _version_out(version: DatasetVersion) -> VersionOut:
    return VersionOut(
        id=version.id, number=version.number, status=version.status,
        source=version.source, label=version.label, message=version.message,
        display_name=version.display_name, created_at=version.created_at,
        created_by=version.created_by,
        files=[
            VersionFileOut(
                file_name=f.file_name, content_hash=f.content_hash, size_bytes=f.size_bytes
            )
            for f in version.files
        ],
    )


def _dataset_out(dataset: Dataset) -> DatasetOut:
    return DatasetOut(
        id=dataset.id, project_id=dataset.project_id, data_spec_id=dataset.data_spec_id,
        instance_key=dataset.instance_key, current_version_id=dataset.current_version_id,
        versions=[_version_out(v) for v in dataset.versions],
    )


def _issues_out(issues: list[ValidationIssue]) -> list[IssueOut]:
    return [
        IssueOut(message=i.message, row_index=i.row_index,
                 field_name=i.field_name, severity=i.severity)
        for i in issues
    ]


# ── Reads ───────────────────────────────────────────────────────────────────

@router.get("/projects/{project_id}/datasets", response_model=list[DatasetOut])
async def list_for_project(datasets: Datasets, project_id: uuid.UUID) -> list[DatasetOut]:
    return [_dataset_out(d) for d in await datasets.list_for_project(project_id)]


@router.get("/datasets/{dataset_id}", response_model=DatasetOut)
async def get_one(datasets: Datasets, dataset_id: uuid.UUID) -> DatasetOut:
    return _dataset_out(await use_cases._dataset(datasets, dataset_id))


@router.get("/datasets/{dataset_id}/versions/{number}/records")
async def version_records(
    datasets: Datasets, session: Session, dataset_id: uuid.UUID, number: int
) -> list[dict[str, Any]]:
    """Row projection of a version — derived from the blob, so rebuildable."""
    return await use_cases.read_version_records(
        datasets, SqlRecordProjection(session), dataset_id, number
    )


@router.get("/datasets/{dataset_id}/versions/{number}/issues", response_model=list[IssueOut])
async def version_issues(
    datasets: Datasets, dataset_id: uuid.UUID, number: int
) -> list[IssueOut]:
    dataset = await use_cases._dataset(datasets, dataset_id)
    version = dataset.version_by_number(number)
    if version is None:
        return []
    return _issues_out(await datasets.issues_for(version.id))


@router.get("/datasets/{dataset_id}/versions/{number}/files/{file_name}")
async def download_file(
    datasets: Datasets, blobs: Blobs, dataset_id: uuid.UUID, number: int, file_name: str
) -> Response:
    """The exact bytes of the published version — never a re-encoding."""
    payload = await use_cases.download_version_file(
        datasets, blobs, dataset_id, number, file_name
    )
    return Response(
        content=payload,
        media_type="application/octet-stream",
        headers={"Content-Disposition": f'attachment; filename="{file_name}"'},
    )


# ── Writes ──────────────────────────────────────────────────────────────────

@router.post(
    "/projects/{project_id}/datasets/{data_spec_id}/versions",
    response_model=UploadOut,
    status_code=201,
)
async def upload(
    datasets: Datasets,
    catalog: Catalog,
    blobs: Blobs,
    session: Session,
    project_id: uuid.UUID,
    data_spec_id: str,
    files: Annotated[list[UploadFile], File()],
    instance_key: Annotated[str | None, Form()] = None,
    label: Annotated[str | None, Form()] = None,
    message: Annotated[str | None, Form()] = None,
) -> UploadOut:
    """Create a version from uploaded files.

    A ZIP is expanded: a shapefile ships as four files, and asking the user to
    upload them one by one would be a trap.
    """
    payloads: dict[str, bytes] = {}
    for upload_file in files:
        raw = await upload_file.read()
        name = upload_file.filename or "sans-nom"
        if name.lower().endswith(".zip"):
            payloads.update(_expand_zip(raw))
        else:
            payloads[name] = raw

    dataset, version, issues = await use_cases.upload_version(
        datasets, catalog, blobs, SqlRecordProjection(session),
        project_id=project_id, data_spec_id=data_spec_id, files=payloads,
        instance_key=instance_key, label=label, message=message,
    )
    await session.commit()
    return UploadOut(
        dataset=_dataset_out(dataset), version=_version_out(version),
        issues=_issues_out(issues),
    )


def _expand_zip(raw: bytes) -> dict[str, bytes]:
    """Flatten a ZIP: only the leaf names matter, the archive's tree does not."""
    with zipfile.ZipFile(BytesIO(raw)) as archive:
        return {
            entry.filename.rsplit("/", 1)[-1]: archive.read(entry)
            for entry in archive.infolist()
            if not entry.is_dir() and not entry.filename.startswith("__MACOSX")
        }


@router.get("/datasets/{dataset_id}/draft")
async def read_draft(
    datasets: Datasets, catalog: Catalog, blobs: Blobs, session: Session, dataset_id: uuid.UUID
) -> list[dict[str, Any]]:
    """Rows being edited, seeded from the current version when empty."""
    return await use_cases.read_draft(
        datasets, catalog, blobs, SqlDraftStore(session), dataset_id
    )


@router.put("/datasets/{dataset_id}/draft")
async def write_draft(
    datasets: Datasets, session: Session, dataset_id: uuid.UUID, payload: DraftIn
) -> dict[str, int]:
    rows = [{k: str(v) for k, v in row.items()} for row in payload.rows]
    written = await use_cases.write_draft(datasets, SqlDraftStore(session), dataset_id, rows)
    await session.commit()
    return {"rows": written}


@router.post("/datasets/{dataset_id}/draft/publish", response_model=UploadOut, status_code=201)
async def publish_draft(
    datasets: Datasets,
    catalog: Catalog,
    blobs: Blobs,
    session: Session,
    dataset_id: uuid.UUID,
    payload: PublishIn,
) -> UploadOut:
    """Freeze the draft into an immutable version.

    The only place where bytes are produced from rows.
    """
    version, issues = await use_cases.publish_draft(
        datasets, catalog, blobs, SqlDraftStore(session), SqlRecordProjection(session),
        dataset_id, label=payload.label, message=payload.message,
    )
    await session.commit()
    dataset = await use_cases._dataset(datasets, dataset_id)
    return UploadOut(
        dataset=_dataset_out(dataset), version=_version_out(version),
        issues=_issues_out(issues),
    )


@router.post("/projects/{project_id}/datasets/resolve")
async def resolve(
    datasets: Datasets, project_id: uuid.UUID, payload: ResolveIn
) -> dict[str, str]:
    """Freeze the full set of versions a run would use.

    Covers every dataset, not only the pinned ones — that is what keeps a run
    reproducible once newer versions are published.
    """
    return await use_cases.resolve_versions(datasets, project_id, payload.pins)
