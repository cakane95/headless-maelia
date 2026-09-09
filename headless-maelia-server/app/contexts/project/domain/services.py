"""Project context rules — pure functions."""

from collections.abc import Iterable, Mapping

from app.contexts.catalog.domain.models import DataSpec
from app.contexts.project.domain.models import Completion, CompletionEntry, FileStatus

# A project's data inventory, as the `dataset` context provides it:
#   data_spec_id -> {instance_key or "": status}
Inventory = Mapping[str, Mapping[str, FileStatus]]


def compute_completion(
    applicable: Iterable[DataSpec],
    inventory: Inventory,
) -> Completion:
    """Cross the expected files with the data actually supplied.

    Pure function: it knows neither the database nor the object store. The
    `dataset` context hands it an inventory, it returns a state — which is what
    makes it testable without infrastructure.
    """
    entries: list[CompletionEntry] = []

    for spec in applicable:
        supplied = inventory.get(spec.id, {})
        entries.append(
            CompletionEntry(
                data_spec_id=spec.id,
                label=spec.label,
                module=spec.module,
                status=_aggregate(supplied.values()),
                instances=len(supplied),
                multi_instance=spec.multi_instance,
                required=spec.required,
            )
        )

    entries.sort(key=lambda e: (e.module, e.data_spec_id))
    return Completion(entries=tuple(entries))


def _aggregate(statuses: Iterable[FileStatus]) -> FileStatus:
    """Aggregated state of one file kind.

    For a multi-instance family a single invalid file makes the whole set
    unusable: the model reads them all.
    """
    values = list(statuses)
    if not values:
        return FileStatus.MISSING
    if FileStatus.INVALID in values:
        return FileStatus.INVALID
    if all(v is FileStatus.VALID for v in values):
        return FileStatus.VALID
    return FileStatus.DRAFT


def missing_files(completion: Completion) -> list[str]:
    """What blocks a launch: required files with no valid version."""
    return [
        e.data_spec_id
        for e in completion.entries
        if e.required and e.status is not FileStatus.VALID
    ]
