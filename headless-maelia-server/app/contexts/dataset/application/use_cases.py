"""Dataset use cases: upload, edit, publish, resolve.

The rule that governs this module: **bytes are never regenerated after
publication**.

  - upload -> the received bytes become the blob as they are;
  - edit   -> the draft rows are serialised ONCE, at publication.

Afterwards a version is only ever copied. That is what stops a `;`-delimited,
transposed, meta-column or ISO-8859-1 file from drifting between what was
validated and what GAMA reads.
"""

import uuid
from collections.abc import Sequence
from dataclasses import dataclass, replace
from enum import StrEnum

from app.contexts.catalog.domain.models import DataSpec, FileKind
from app.contexts.catalog.domain.ports import CatalogRepository
from app.contexts.catalog.domain.services import resolve_spec
from app.contexts.dataset.application.materialize import OverlayFile
from app.contexts.dataset.domain import codec
from app.contexts.dataset.domain.models import (
    Dataset,
    DatasetVersion,
    ValidationIssue,
    VersionFile,
    VersionSource,
    VersionStatus,
)
from app.contexts.dataset.domain.ports import (
    BlobStore,
    DatasetRepository,
    DraftStore,
    RecordProjection,
)
from app.contexts.dataset.domain.services import (
    SHAPEFILE_EXTENSIONS,
    blocking,
    check_shapefile_set,
    instance_key_for,
    normalise_upload_name,
    validate,
)
from app.shared.errors import ConflictError, DomainError, NotFoundError, ValidationError


async def _spec(catalog: CatalogRepository, data_spec_id: str) -> DataSpec:
    spec = await catalog.get(data_spec_id)
    if spec is None:
        raise NotFoundError(f"type de donnée inconnu : {data_spec_id}")
    return spec


async def get_or_create_dataset(
    datasets: DatasetRepository,
    project_id: uuid.UUID,
    data_spec_id: str,
    instance_key: str | None,
) -> Dataset:
    existing = await datasets.find(project_id, data_spec_id, instance_key)
    if existing is not None:
        return existing
    return await datasets.save(Dataset(
        id=uuid.uuid4(),
        project_id=project_id,
        data_spec_id=data_spec_id,
        instance_key=instance_key,
    ))


async def upload_version(
    datasets: DatasetRepository,
    catalog: CatalogRepository,
    blobs: BlobStore,
    projection: RecordProjection,
    project_id: uuid.UUID,
    data_spec_id: str,
    files: dict[str, bytes],
    instance_key: str | None = None,
    label: str | None = None,
    message: str | None = None,
    author: str | None = None,
) -> tuple[Dataset, DatasetVersion, list[ValidationIssue]]:
    """Create a version from uploaded files.

    The received bytes are stored as they are — never re-encoded. Only the row
    projection is derived from them.
    """
    if not files:
        raise ValidationError("aucun fichier fourni")

    spec = await _spec(catalog, data_spec_id)
    if spec.multi_instance and not instance_key:
        raise ValidationError(
            f"{spec.id} attend plusieurs fichiers : précisez lequel (instance_key)"
        )

    named = {
        normalise_upload_name(spec, name, instance_key): payload
        for name, payload in files.items()
    }

    set_issues = check_shapefile_set(spec, list(named))
    if set_issues:
        raise ValidationError(set_issues[0].message)

    dataset = await get_or_create_dataset(datasets, project_id, data_spec_id, instance_key)

    stored: list[VersionFile] = []
    for file_name, payload in sorted(named.items()):
        digest, size = await blobs.put(payload)
        stored.append(VersionFile(file_name, digest, size))

    version = DatasetVersion(
        id=uuid.uuid4(),
        dataset_id=dataset.id,
        number=dataset.next_version_number,
        source=VersionSource.UPLOAD,
        label=label,
        message=message,
        created_by=author,
        files=tuple(stored),
    )
    await datasets.add_version(version)

    issues, status = await _validate_and_project(
        datasets, blobs, projection, spec, version, named
    )
    return await datasets.get(dataset.id), replace(version, status=status), issues


async def _validate_and_project(
    datasets: DatasetRepository,
    blobs: BlobStore,
    projection: RecordProjection,
    spec: DataSpec,
    version: DatasetVersion,
    payloads: dict[str, bytes] | None = None,
) -> tuple[list[ValidationIssue], VersionStatus]:
    """Validate a version and store its row projection.

    The projection is derived from the blob, so losing it costs nothing: it can
    always be rebuilt from the bytes.
    """
    issues: list[ValidationIssue] = []

    if spec.tabular:
        main = spec.file_name or version.files[0].file_name
        raw = (payloads or {}).get(main)
        if raw is None:
            entry = version.file(main) or version.files[0]
            raw = await blobs.get(entry.content_hash)

        table = codec.decode(raw, spec)
        issues = validate(table, spec)
        await projection.replace(version.id, table.as_records())

    status = VersionStatus.INVALID if blocking(issues) else VersionStatus.VALID
    await datasets.update_version_status(version.id, status)
    await datasets.replace_issues(version.id, issues)

    if status is VersionStatus.VALID:
        await datasets.set_current_version(version.dataset_id, version.id)

    return issues, status


async def read_draft(
    datasets: DatasetRepository,
    catalog: CatalogRepository,
    blobs: BlobStore,
    drafts: DraftStore,
    dataset_id: uuid.UUID,
) -> list[dict[str, str]]:
    """Rows being edited.

    An empty draft is seeded from the current version, so editing starts from what
    the model reads today rather than from a blank page.
    """
    dataset = await _dataset(datasets, dataset_id)
    rows = await drafts.read(dataset_id)
    if rows:
        return rows

    current = dataset.current_version
    if current is None or not current.files:
        return []

    spec = await _spec(catalog, dataset.data_spec_id)
    if not spec.tabular:
        return []

    raw = await blobs.get(current.files[0].content_hash)
    return codec.decode(raw, spec).as_records()


async def write_draft(
    datasets: DatasetRepository,
    drafts: DraftStore,
    dataset_id: uuid.UUID,
    rows: list[dict[str, str]],
) -> int:
    await _dataset(datasets, dataset_id)
    await drafts.replace(dataset_id, rows)
    return len(rows)


async def publish_draft(
    datasets: DatasetRepository,
    catalog: CatalogRepository,
    blobs: BlobStore,
    drafts: DraftStore,
    projection: RecordProjection,
    dataset_id: uuid.UUID,
    label: str | None = None,
    message: str | None = None,
    author: str | None = None,
) -> tuple[DatasetVersion, list[ValidationIssue]]:
    """Freeze the draft into an immutable version.

    This is the ONLY place where bytes are produced from rows. Once written they
    become the reference and are never regenerated.
    """
    dataset = await _dataset(datasets, dataset_id)
    spec = await _spec(catalog, dataset.data_spec_id)

    if not spec.tabular:
        raise ConflictError(
            f"{spec.id} n'est pas un fichier tabulaire : il se met à jour par téléversement"
        )

    rows = await drafts.read(dataset_id)
    if not rows:
        raise ValidationError("le brouillon est vide : rien à publier")

    file_name = spec.file_name or dataset.instance_key or "data.csv"

    # A draft inherits the PHYSICAL shape of the version it derives from: field
    # order, encoding, BOM, line terminator, meta columns. Rebuilding any of that
    # from the draft rows would silently rewrite the file — the draft is stored as
    # JSONB, whose key order the database is free to normalise.
    template = await _current_table(datasets, blobs, spec, dataset, file_name)
    columns = template.columns if template else tuple(rows[0].keys())
    dialect = template.dialect if template else codec.Dialect()

    table = codec.Table.from_records(
        [{k: str(v) for k, v in row.items()} for row in rows], columns, dialect
    )
    payload = codec.encode(table, spec)

    digest, size = await blobs.put(payload)

    version = DatasetVersion(
        id=uuid.uuid4(),
        dataset_id=dataset.id,
        number=dataset.next_version_number,
        source=VersionSource.EDIT,
        label=label,
        message=message,
        created_by=author,
        files=(VersionFile(file_name, digest, size),),
    )
    await datasets.add_version(version)

    issues, status = await _validate_and_project(
        datasets, blobs, projection, spec, version, {file_name: payload}
    )
    await drafts.clear(dataset_id)
    return replace(version, status=status), issues


async def _current_table(
    datasets: DatasetRepository,
    blobs: BlobStore,
    spec: DataSpec,
    dataset: Dataset,
    file_name: str,
) -> codec.Table | None:
    """Decode the current version, to reuse its physical shape when publishing.

    Returns None for a first publication: there is nothing to inherit, and the
    draft's own key order is then the only order available.
    """
    current = dataset.current_version
    if current is None:
        return None
    entry = current.file(file_name)
    if entry is None:
        return None
    return codec.decode(await blobs.get(entry.content_hash), spec)


async def read_version_records(
    datasets: DatasetRepository,
    projection: RecordProjection,
    dataset_id: uuid.UUID,
    number: int,
) -> list[dict[str, str]]:
    dataset = await _dataset(datasets, dataset_id)
    version = dataset.version_by_number(number)
    if version is None:
        raise NotFoundError(f"version {number} introuvable")
    return await projection.read(version.id)


async def download_version_file(
    datasets: DatasetRepository,
    blobs: BlobStore,
    dataset_id: uuid.UUID,
    number: int,
    file_name: str,
) -> bytes:
    """The exact bytes of a published version — never a re-encoding."""
    dataset = await _dataset(datasets, dataset_id)
    version = dataset.version_by_number(number)
    if version is None:
        raise NotFoundError(f"version {number} introuvable")
    entry = version.file(file_name)
    if entry is None:
        raise NotFoundError(f"fichier {file_name} absent de la version {number}")
    return await blobs.get(entry.content_hash)


async def build_overlays(
    datasets: DatasetRepository,
    catalog: CatalogRepository,
    blobs: BlobStore,
    resolved: dict[str, str],
) -> list[OverlayFile]:
    """Turn a frozen resolution into files to overlay on the baseline.

    `resolved` maps dataset_id -> version_id, as the run recorded it. Nothing is
    re-encoded here: blob bytes go straight to disk.
    """
    overlays: list[OverlayFile] = []

    for dataset_id, version_id in resolved.items():
        dataset = await datasets.get(uuid.UUID(str(dataset_id)))
        if dataset is None:
            continue
        version = dataset.version(uuid.UUID(str(version_id)))
        if version is None:
            continue

        spec = await catalog.get(dataset.data_spec_id)
        if spec is None:
            continue

        for entry in version.files:
            overlays.append(OverlayFile(
                relative_dir=spec.relative_dir,
                file_name=entry.file_name,
                content=await blobs.get(entry.content_hash),
            ))

    return overlays


async def resolve_versions(
    datasets: DatasetRepository,
    project_id: uuid.UUID,
    pins: dict[str, str] | None = None,
) -> dict[str, str]:
    """Freeze the full set of versions a run will use.

    Pinned datasets take the requested version; every other one follows its
    latest valid version. The result covers ALL datasets, not only the pinned
    ones — that is what keeps a run reproducible once newer versions appear.
    """
    pins = {str(k): str(v) for k, v in (pins or {}).items()}
    resolved: dict[str, str] = {}

    for dataset in await datasets.list_for_project(project_id):
        key = str(dataset.id)
        if key in pins:
            pinned = dataset.version(uuid.UUID(pins[key]))
            if pinned is None:
                raise ValidationError(
                    f"version épinglée introuvable pour {dataset.data_spec_id}"
                )
            resolved[key] = str(pinned.id)
            continue

        current = dataset.current_version
        if current is not None:
            resolved[key] = str(current.id)

    return resolved


async def _dataset(datasets: DatasetRepository, dataset_id: uuid.UUID) -> Dataset:
    dataset = await datasets.get(dataset_id)
    if dataset is None:
        raise NotFoundError(f"jeu de données inconnu : {dataset_id}")
    return dataset


def file_kind_is_binary(spec: DataSpec) -> bool:
    return spec.kind in {FileKind.SHAPEFILE, FileKind.IMAGE}


class ImportOutcome(StrEnum):
    IMPORTED = "IMPORTED"    # version created and valid
    INVALID = "INVALID"      # version created, validation found problems
    IGNORED = "IGNORED"      # no catalog entry matches this file name
    ERROR = "ERROR"          # refused (incomplete shapefile, unreadable file...)


@dataclass(frozen=True, slots=True)
class ImportEntry:
    file_names: tuple[str, ...]
    outcome: ImportOutcome
    data_spec_id: str | None = None
    instance_key: str | None = None
    dataset_id: uuid.UUID | None = None
    version_number: int | None = None
    issues: int = 0
    message: str | None = None


@dataclass(frozen=True, slots=True)
class ImportReport:
    entries: tuple[ImportEntry, ...]

    @property
    def analysed(self) -> int:
        return len(self.entries)

    @property
    def imported(self) -> int:
        return sum(1 for e in self.entries if e.outcome is ImportOutcome.IMPORTED)

    @property
    def invalid(self) -> int:
        return sum(1 for e in self.entries if e.outcome is ImportOutcome.INVALID)

    @property
    def ignored(self) -> int:
        return sum(1 for e in self.entries if e.outcome is ImportOutcome.IGNORED)

    @property
    def errors(self) -> int:
        return sum(1 for e in self.entries if e.outcome is ImportOutcome.ERROR)


def group_archive(members: dict[str, bytes], specs: Sequence[DataSpec]) -> list[dict]:
    """Group archive members into upload units, one per target dataset.

    Two rules do the work:
      - a shapefile travels as a set, so its sidecars are grouped by base name;
      - the path inside the archive is ignored, only the file name matters —
        users zip their folder the way they please.
    """
    groups: dict[tuple[str, str | None], dict] = {}
    unmatched: list[dict] = []

    for path, payload in sorted(members.items()):
        file_name = path.replace("\\", "/").rsplit("/", 1)[-1]
        if not file_name or file_name.startswith("."):
            continue

        spec = resolve_spec(specs, file_name)
        if spec is None and file_name.lower().endswith(SHAPEFILE_EXTENSIONS):
            # A sidecar carries no spec of its own: it follows its .shp.
            stem = file_name.rsplit(".", 1)[0]
            spec = resolve_spec(specs, f"{stem}.shp")

        if spec is None:
            unmatched.append({"files": {file_name: payload}, "spec": None, "instance": None})
            continue

        instance = instance_key_for(spec, file_name)
        key = (spec.id, instance)
        group = groups.setdefault(key, {"files": {}, "spec": spec, "instance": instance})
        group["files"][file_name] = payload

    return [*groups.values(), *unmatched]


async def import_archive(
    datasets: DatasetRepository,
    catalog: CatalogRepository,
    blobs: BlobStore,
    projection: RecordProjection,
    project_id: uuid.UUID,
    members: dict[str, bytes],
    label: str | None = None,
    author: str | None = None,
) -> ImportReport:
    """Initialise a project from an archive of input files.

    Each group becomes one version. A failing group never aborts the others: the
    point of a bulk import is to get as far as possible and report the rest.
    """
    specs = await catalog.list_all()
    entries: list[ImportEntry] = []

    for group in group_archive(members, specs):
        names = tuple(sorted(group["files"]))
        spec: DataSpec | None = group["spec"]

        if spec is None:
            entries.append(ImportEntry(names, ImportOutcome.IGNORED,
                                       message="aucun type de fichier ne correspond à ce nom"))
            continue

        try:
            dataset, version, issues = await upload_version(
                datasets, catalog, blobs, projection,
                project_id=project_id,
                data_spec_id=spec.id,
                files=group["files"],
                instance_key=group["instance"],
                label=label,
                author=author,
            )
        except DomainError as exc:
            entries.append(ImportEntry(names, ImportOutcome.ERROR, data_spec_id=spec.id,
                                       instance_key=group["instance"], message=str(exc)))
            continue

        entries.append(ImportEntry(
            file_names=names,
            outcome=ImportOutcome.IMPORTED if version.status is VersionStatus.VALID
            else ImportOutcome.INVALID,
            data_spec_id=spec.id,
            instance_key=group["instance"],
            dataset_id=dataset.id,
            version_number=version.number,
            issues=len(issues),
        ))

    return ImportReport(entries=tuple(entries))
