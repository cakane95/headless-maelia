"""Loading of the reference catalog.

The seed is produced by `scripts/generate_catalog_seed.py` from the **GAML code**
and the **files actually shipped**. Regenerating it after a model version bump is
the normal way to bring the catalog up to date.

Idempotent and non-destructive: only `SEED` specs are overwritten. Anything an
administrator created or edited (`origin = USER`) is preserved.
"""

import json
import logging
import pathlib

from app.contexts.catalog.domain.models import (
    DataSpec,
    FieldSpec,
    FieldType,
    FileKind,
    Granularity,
    Orientation,
    OutputFileSpec,
    OutputSpec,
    ParameterSpec,
    ParameterType,
)
from app.contexts.catalog.domain.ports import CatalogRepository

log = logging.getLogger("maelia.catalog.seed")

SEED_FILE = pathlib.Path(__file__).with_name("seed") / "dataspecs.json"


def load_seed(path: pathlib.Path | None = None) -> list[DataSpec]:
    """Read the reference JSON and turn it into domain objects."""
    source = path or SEED_FILE
    if not source.is_file():
        log.warning("catalog seed not found: %s", source)
        return []

    return [_to_spec(entry) for entry in json.loads(source.read_text(encoding="utf-8"))]


def _to_spec(entry: dict) -> DataSpec:
    # The generator only fills in field names: types and labels are completed
    # afterwards from the administration screens.
    fields = tuple(
        FieldSpec(name=name, type=FieldType.STRING, position=position)
        for position, name in enumerate(entry.get("fields") or [])
    )
    return DataSpec(
        id=entry["id"],
        label=entry["label"],
        module=entry["module"],
        kind=FileKind(entry["kind"]),
        relative_dir=entry["relative_dir"],
        file_name=entry.get("file_name"),
        file_name_pattern=entry.get("file_name_pattern"),
        orientation=Orientation(entry["orientation"]) if entry.get("orientation") else None,
        delimiter=entry.get("delimiter") or ";",
        has_header=entry.get("has_header", True),
        matrix_value_start_index=entry.get("matrix_value_start_index"),
        required=entry.get("required", True),
        required_if=entry.get("required_if"),
        depends_on=tuple(entry.get("depends_on") or ()),
        gaml_source=entry.get("gaml_source"),
        origin="SEED",
        fields=fields,
    )


async def apply_seed(repository: CatalogRepository) -> dict[str, int]:
    """Write the reference catalog while respecting local customisations."""
    specs = load_seed()
    if not specs:
        return {"read": 0, "written": 0, "preserved": 0, "removed": 0}

    existing = {s.id: s for s in await repository.list_all()}
    written = preserved = 0

    for spec in specs:
        current = existing.get(spec.id)
        if current is not None and current.origin == "USER":
            preserved += 1
            continue
        await repository.upsert(spec)
        written += 1

    # A SEED spec absent from the current seed was renamed or dropped from the
    # model: leaving it would keep asking for a file GAMA no longer reads. USER
    # specs do not belong to the seed and are left untouched.
    expected = {s.id for s in specs}
    obsolete = [s.id for s in existing.values() if s.origin == "SEED" and s.id not in expected]
    for spec_id in obsolete:
        await repository.delete(spec_id)

    log.info(
        "catalog: %d written, %d preserved, %d obsolete removed",
        written, preserved, len(obsolete),
    )
    return {
        "read": len(specs), "written": written,
        "preserved": preserved, "removed": len(obsolete),
    }


PARAMETER_SEED_FILE = pathlib.Path(__file__).with_name("seed") / "parameters.json"


def load_parameter_seed(path: pathlib.Path | None = None) -> list[ParameterSpec]:
    """Read the parameter reference, produced from `launcherBase.gaml`."""
    source = path or PARAMETER_SEED_FILE
    if not source.is_file():
        log.warning("parameter seed not found: %s", source)
        return []

    return [
        ParameterSpec(
            name=entry["name"],
            label=entry["label"],
            group=entry["group"],
            type=ParameterType(entry["type"]),
            default=entry.get("default"),
            launcher_default=entry.get("launcher_default"),
            allowed_values=tuple(entry.get("allowed_values") or ()),
            system=entry.get("system", False),
            editable=entry.get("editable", True),
            options_from=entry.get("options_from"),
            enabled_if=entry.get("enabled_if"),
            origin="SEED",
        )
        for entry in json.loads(source.read_text(encoding="utf-8"))
    ]


async def apply_parameter_seed(repository) -> dict[str, int]:
    """Write the parameter catalog, preserving local customisations."""
    specs = load_parameter_seed()
    if not specs:
        return {"read": 0, "written": 0, "preserved": 0}

    existing = {s.name: s for s in await repository.list_all()}
    written = preserved = 0

    for spec in specs:
        current = existing.get(spec.name)
        if current is not None and current.origin == "USER":
            preserved += 1
            continue
        await repository.upsert(spec)
        written += 1

    log.info("parameters: %d written, %d preserved", written, preserved)
    return {"read": len(specs), "written": written, "preserved": preserved}


OUTPUT_SEED_FILE = pathlib.Path(__file__).with_name("seed") / "outputs.json"


def load_output_seed(path: pathlib.Path | None = None) -> list[OutputSpec]:
    """Read the output reference, produced from the model's own routing code.

    `scripts/generate_output_seed.py` follows `ecritureResultats.gaml` down to
    the literal file names, which is the only place the flag → file link exists.
    """
    source = path or OUTPUT_SEED_FILE
    if not source.is_file():
        log.warning("output seed not found: %s", source)
        return []

    return [
        OutputSpec(
            id=entry["id"],
            label=entry["label"],
            theme=entry["theme"],
            files=tuple(
                OutputFileSpec(
                    name=item["name"],
                    granularity=Granularity(item.get("granularity") or "UNKNOWN"),
                )
                for item in entry.get("files") or []
            ),
            description=entry.get("description"),
            flag=entry.get("flag"),
            produced_if=entry.get("produced_if"),
            guard_source=entry.get("guard_source"),
            exact=entry.get("exact", True),
            gaml_source=entry.get("gaml_source"),
            origin="SEED",
        )
        for entry in json.loads(source.read_text(encoding="utf-8"))
    ]


async def apply_output_seed(repository) -> dict[str, int]:
    """Write the output catalog, preserving local customisations.

    Same contract as the input catalog: a SEED entry the model no longer routes
    is removed, because keeping it would announce a file no run can produce.
    """
    specs = load_output_seed()
    if not specs:
        return {"read": 0, "written": 0, "preserved": 0, "removed": 0}

    existing = {s.id: s for s in await repository.list_all()}
    written = preserved = 0

    for spec in specs:
        current = existing.get(spec.id)
        if current is not None and current.origin == "USER":
            preserved += 1
            continue
        await repository.upsert(spec)
        written += 1

    expected = {s.id for s in specs}
    obsolete = [s.id for s in existing.values() if s.origin == "SEED" and s.id not in expected]
    for spec_id in obsolete:
        await repository.delete(spec_id)

    log.info(
        "outputs: %d written, %d preserved, %d obsolete removed",
        written, preserved, len(obsolete),
    )
    return {
        "read": len(specs), "written": written,
        "preserved": preserved, "removed": len(obsolete),
    }
