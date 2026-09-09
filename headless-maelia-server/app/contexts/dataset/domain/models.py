"""Dataset domain model — pure.

A `Dataset` is one logical file of a project; its `DatasetVersion`s are immutable
snapshots. A scenario pins the versions it cares about, everything else follows
the latest valid one.

Storage tiers, and which is authoritative:
  - the bytes of a version live in the object store — **they are the reference**;
  - the row projection lives in the database — derived, rebuildable;
  - the draft is mutable, until publication turns it into a version.
"""

import uuid
from dataclasses import dataclass, field
from datetime import datetime
from enum import StrEnum


class VersionStatus(StrEnum):
    DRAFT = "DRAFT"        # created, not validated yet
    VALID = "VALID"        # validated without blocking issue
    INVALID = "INVALID"    # validated, issues found


class VersionSource(StrEnum):
    UPLOAD = "UPLOAD"      # bytes received as is
    EDIT = "EDIT"          # serialised once from the draft


class Severity(StrEnum):
    ERROR = "ERROR"
    WARNING = "WARNING"


@dataclass(frozen=True, slots=True)
class ValidationIssue:
    message: str
    row_index: int | None = None
    field_name: str | None = None
    severity: Severity = Severity.ERROR


@dataclass(frozen=True, slots=True)
class VersionFile:
    """One file of a version: a CSV has one, a shapefile has four.

    `content_hash` addresses the bytes in the object store; two identical
    versions share the same blob.
    """

    file_name: str
    content_hash: str
    size_bytes: int


@dataclass(frozen=True, slots=True)
class DatasetVersion:
    """Immutable snapshot. Once published, a version never changes."""

    id: uuid.UUID
    dataset_id: uuid.UUID
    number: int
    status: VersionStatus = VersionStatus.DRAFT
    source: VersionSource = VersionSource.UPLOAD
    label: str | None = None
    message: str | None = None
    created_at: datetime | None = None
    created_by: str | None = None
    files: tuple[VersionFile, ...] = field(default_factory=tuple)

    def __post_init__(self) -> None:
        if self.number < 1:
            raise ValueError("a version number starts at 1")

    @property
    def display_name(self) -> str:
        return self.label or f"v{self.number}"

    def file(self, name: str) -> VersionFile | None:
        return next((f for f in self.files if f.file_name == name), None)


@dataclass(frozen=True, slots=True)
class Dataset:
    """One logical file of the project. A container: content lives in the versions."""

    id: uuid.UUID
    project_id: uuid.UUID
    data_spec_id: str
    # Instance name ('2018.csv', 'prixVentesSC1.csv'); None for a single file.
    instance_key: str | None = None
    current_version_id: uuid.UUID | None = None
    created_at: datetime | None = None
    versions: tuple[DatasetVersion, ...] = field(default_factory=tuple)

    @property
    def next_version_number(self) -> int:
        return max((v.number for v in self.versions), default=0) + 1

    @property
    def current_version(self) -> DatasetVersion | None:
        """The version a scenario gets when it pins nothing.

        The latest VALID one — publishing a version that fails validation must not
        silently become the default for every scenario.
        """
        if self.current_version_id is not None:
            pinned = self.version(self.current_version_id)
            if pinned is not None:
                return pinned
        valid = [v for v in self.versions if v.status is VersionStatus.VALID]
        return max(valid, key=lambda v: v.number, default=None)

    def version(self, version_id: uuid.UUID) -> DatasetVersion | None:
        return next((v for v in self.versions if v.id == version_id), None)

    def version_by_number(self, number: int) -> DatasetVersion | None:
        return next((v for v in self.versions if v.number == number), None)
