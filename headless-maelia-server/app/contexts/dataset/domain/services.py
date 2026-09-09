"""Dataset business rules — pure functions, testable without infrastructure."""

import hashlib
import re
from collections.abc import Sequence

from app.contexts.catalog.domain.models import DataSpec, FileKind
from app.contexts.dataset.domain.codec import Table
from app.contexts.dataset.domain.models import Severity, ValidationIssue

# The four files of a shapefile. `.shp` alone is unusable: the model needs the
# geometry, the index, the attributes and the projection.
SHAPEFILE_EXTENSIONS = (".shp", ".shx", ".dbf", ".prj")
SHAPEFILE_REQUIRED = (".shp", ".shx", ".dbf")


def content_hash(payload: bytes) -> str:
    """Content address of a blob. Two identical files share one entry."""
    return hashlib.sha256(payload).hexdigest()


def validate(table: Table, spec: DataSpec) -> list[ValidationIssue]:
    """Check a table against its schema.

    Pure function: same inputs, same outputs, no side effect — hence testable
    with nothing. It knows no MAELIA file, only a `DataSpec`.
    """
    issues: list[ValidationIssue] = []

    if not table.columns:
        return [ValidationIssue("le fichier est vide")]

    issues.extend(_missing_fields(table, spec))

    # Positional read: a transposed file may repeat a field name, so the column
    # index — not the name — carries the identity.
    for row_index, row in enumerate(table.rows, start=1):
        for position, field_spec in enumerate(spec.fields):
            if position >= len(table.columns) or position >= len(row):
                continue
            raw = row[position]
            if field_spec.required and not raw.strip():
                issues.append(ValidationIssue(
                    "valeur obligatoire absente", row_index, field_spec.name
                ))
            elif raw and not field_spec.accepts(raw):
                issues.append(ValidationIssue(
                    f"« {raw} » n'est pas un {field_spec.type.value.lower()} valide",
                    row_index, field_spec.name,
                ))

    return issues


def _missing_fields(table: Table, spec: DataSpec) -> list[ValidationIssue]:
    """Fields the schema declares required but the file does not carry.

    Compared by name and case-insensitively: exporters vary on capitalisation,
    and a spurious error here would block a perfectly good file.
    """
    present = {c.strip().upper() for c in table.columns}
    return [
        ValidationIssue(f"colonne obligatoire absente : {f.name}", None, f.name)
        for f in spec.fields
        if f.required and f.name.strip().upper() not in present
    ]


def blocking(issues: Sequence[ValidationIssue]) -> list[ValidationIssue]:
    return [i for i in issues if i.severity is Severity.ERROR]


def expected_file_names(spec: DataSpec, instance_key: str | None = None) -> list[str]:
    """File names a version of this spec must carry.

    A shapefile is a set: uploading only the `.shp` produces a version the model
    cannot read, so the four names are expected together.
    """
    if spec.kind is FileKind.SHAPEFILE:
        stem = (spec.file_name or instance_key or "").rsplit(".", 1)[0]
        return [f"{stem}{extension}" for extension in SHAPEFILE_EXTENSIONS]
    return [spec.file_name or instance_key or ""]


def check_shapefile_set(spec: DataSpec, file_names: Sequence[str]) -> list[ValidationIssue]:
    """A shapefile version must carry at least .shp, .shx and .dbf."""
    if spec.kind is not FileKind.SHAPEFILE:
        return []
    present = {name.rsplit(".", 1)[-1].lower() for name in file_names}
    missing = [e for e in SHAPEFILE_REQUIRED if e.lstrip(".") not in present]
    if not missing:
        return []
    return [ValidationIssue(
        "shapefile incomplet : il manque " + ", ".join(missing)
    )]


def instance_key_for(spec: DataSpec, file_name: str) -> str | None:
    """Instance name to store for a file, or None for a single-file spec."""
    return file_name if spec.multi_instance else None


def normalise_upload_name(spec: DataSpec, uploaded: str, instance_key: str | None) -> str:
    """Final name the model expects, whatever the uploaded file was called.

    A user may upload `ilots_v2.shp`; the model reads `ilots.shp`. Renaming here
    keeps materialisation a plain byte copy.
    """
    extension = uploaded.rsplit(".", 1)[-1].lower() if "." in uploaded else ""

    if spec.kind is FileKind.SHAPEFILE:
        stem = (spec.file_name or instance_key or uploaded).rsplit(".", 1)[0]
        return f"{stem}.{extension}" if extension else stem

    return spec.file_name or instance_key or uploaded


def match_instance_name(spec: DataSpec, file_name: str) -> bool:
    """Does this file name belong to that multi-instance family?"""
    if not spec.multi_instance:
        return file_name == spec.file_name
    if not spec.file_name_pattern:
        return False
    return re.fullmatch(spec.file_name_pattern, file_name) is not None
