"""Versioned dataset tables.

Two storage tiers, and it must be clear which one is authoritative:

  - `blob`                   -> MinIO, raw bytes. **AUTHORITATIVE**: this is what GAMA reads.
  - `dataset_version_record` -> Postgres, row projection. Derived, disposable.
  - `dataset_draft_record`   -> Postgres, mutable draft before publication.

Rule: bytes are never regenerated after publication.
"""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import (
    BigInteger,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.shared.database import Base


class BlobRow(Base):
    """Content addressed by digest. Two identical versions share the row."""

    __tablename__ = "blob"

    content_hash: Mapped[str] = mapped_column(String(64), primary_key=True)  # sha256 hex
    object_key: Mapped[str] = mapped_column(String(512))  # MinIO key
    size_bytes: Mapped[int] = mapped_column(BigInteger)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class DatasetRow(Base):
    """One logical file of the project. A container: content lives in its versions."""

    __tablename__ = "dataset"
    __table_args__ = (
        # Uniqueness is per instance: a project may hold both 2018.csv and 2019.csv
        # for the same multi-instance spec. COALESCE because NULL is not comparable.
        Index(
            "ux_dataset_project_spec_instance",
            "project_id",
            "data_spec_id",
            text("coalesce(instance_key, '')"),
            unique=True,
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("project.id", ondelete="CASCADE"), index=True
    )
    data_spec_id: Mapped[str] = mapped_column(String(120), ForeignKey("data_spec.id"))
    # Instance name ('2018.csv', 'prixVentesSC1.csv'); NULL = single file.
    instance_key: Mapped[str | None] = mapped_column(String(160), nullable=True)
    # Latest published version: the default when a scenario pins nothing.
    current_version_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("dataset_version.id", ondelete="SET NULL", use_alter=True),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    versions: Mapped[list["DatasetVersionRow"]] = relationship(
        back_populates="dataset",
        cascade="all, delete-orphan",
        foreign_keys="DatasetVersionRow.dataset_id",
        order_by="DatasetVersionRow.number",
    )


class DatasetVersionRow(Base):
    """Immutable snapshot. Once published, a version never changes."""

    __tablename__ = "dataset_version"
    __table_args__ = (
        UniqueConstraint("dataset_id", "number", name="ux_dataset_version_number"),
        CheckConstraint("number >= 1", name="ck_dataset_version_number"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    dataset_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("dataset.id", ondelete="CASCADE"), index=True
    )
    number: Mapped[int] = mapped_column(Integer)
    # Business label: "ITK bas intrants", "irrigation -20 %".
    label: Mapped[str | None] = mapped_column(String(120), nullable=True)
    message: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="DRAFT")  # VALID | INVALID | DRAFT
    source: Mapped[str] = mapped_column(String(20), default="UPLOAD")  # UPLOAD | EDIT
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    created_by: Mapped[str | None] = mapped_column(String(120), nullable=True)

    dataset: Mapped[DatasetRow] = relationship(
        back_populates="versions", foreign_keys=[dataset_id]
    )
    files: Mapped[list["DatasetVersionFileRow"]] = relationship(
        back_populates="version", cascade="all, delete-orphan"
    )


class DatasetVersionFileRow(Base):
    """The files of a version: one for a CSV, four for a shapefile."""

    __tablename__ = "dataset_version_file"
    __table_args__ = (
        UniqueConstraint("version_id", "file_name", name="ux_version_file_name"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    version_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("dataset_version.id", ondelete="CASCADE"), index=True
    )
    file_name: Mapped[str] = mapped_column(String(255))  # final name the model expects
    content_hash: Mapped[str] = mapped_column(String(64), ForeignKey("blob.content_hash"))
    size_bytes: Mapped[int] = mapped_column(BigInteger)

    version: Mapped[DatasetVersionRow] = relationship(back_populates="files")


class DatasetVersionRecordRow(Base):
    """Tabular projection of a version — DERIVED from the blob, hence rebuildable.

    Powers the grid view and the diff between two versions. Only exists for CSV
    specs.
    """

    __tablename__ = "dataset_version_record"
    __table_args__ = (
        Index("ix_version_record_order", "version_id", "row_index"),
        Index("ix_version_record_values", "values", postgresql_using="gin"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    version_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("dataset_version.id", ondelete="CASCADE")
    )
    row_index: Mapped[int] = mapped_column(Integer)
    values: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)


class DatasetDraftRecordRow(Base):
    """Mutable draft: what is edited before publishing a version."""

    __tablename__ = "dataset_draft_record"
    __table_args__ = (Index("ix_draft_record_order", "dataset_id", "row_index"),)

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    dataset_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("dataset.id", ondelete="CASCADE")
    )
    row_index: Mapped[int] = mapped_column(Integer)
    values: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)


class ValidationIssueRow(Base):
    """A validation problem, attached to a published version OR to the draft."""

    __tablename__ = "validation_issue"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    version_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("dataset_version.id", ondelete="CASCADE"),
        nullable=True, index=True,
    )
    dataset_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("dataset.id", ondelete="CASCADE"),
        nullable=True, index=True,
    )
    row_index: Mapped[int | None] = mapped_column(Integer, nullable=True)
    field_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    severity: Mapped[str] = mapped_column(String(10), default="ERROR")
    message: Mapped[str] = mapped_column(Text)
