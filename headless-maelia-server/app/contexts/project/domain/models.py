"""Project domain model — pure.

A project is a **territory** plus a **modelling configuration**. Together they
decide which input files are expected: the territory says where to read them, the
configuration says which ones are needed.
"""

import uuid
from dataclasses import dataclass, field, replace
from datetime import datetime
from enum import StrEnum
from typing import Any

# Parameters of `launcherBase.gaml` that drive input-file applicability (see the
# catalog `required_if` expressions). Values are the launcher's own, so a fresh
# project starts from a coherent configuration.
DEFAULT_CONFIGURATION: dict[str, Any] = {
    "executerModeleAgricole": True,
    "executerModeleHydrographique": False,
    "nomChoixModeleHydrographique": "SWAT",
    "executerModeleNormatif": False,
    "executerModeleElevage": False,
    "executerBarrage": True,
    "avecIlotsHorsZone": False,
    "nomChoixAssolement": "Donnees",
    "nomChoixModeleCroissancePlante": "AqYieldNC",
    "nomChoixModeleCroissancePrairie": "HerbSimNC",
    "isPrelevementEtRejetSimules": True,
    "nomScenarioClimatique": "",
}


class FileStatus(StrEnum):
    """State of an expected input file, from the project's point of view."""

    MISSING = "MISSING"    # expected, nothing supplied
    DRAFT = "DRAFT"        # data exists, no published version
    VALID = "VALID"        # at least one published, valid version
    INVALID = "INVALID"    # published version, but validation failed


@dataclass(frozen=True, slots=True)
class Project:
    id: uuid.UUID
    name: str
    territory: str
    description: str | None = None
    modeling_config: dict[str, Any] = field(default_factory=dict)
    created_at: datetime | None = None
    updated_at: datetime | None = None

    @staticmethod
    def create(name: str, territory: str, description: str | None = None,
               modeling_config: dict[str, Any] | None = None) -> "Project":
        return Project(
            id=uuid.uuid4(),
            name=name,
            territory=territory,
            description=description,
            modeling_config={**DEFAULT_CONFIGURATION, **(modeling_config or {})},
        )

    def with_configuration(self, config: dict[str, Any]) -> "Project":
        """The given configuration completes the previous one: an omitted setting
        keeps its value, it does not fall back to the launcher default."""
        return replace(self, modeling_config={**self.modeling_config, **config})


@dataclass(frozen=True, slots=True)
class CompletionEntry:
    """One expected file and its state within the project."""

    data_spec_id: str
    label: str
    module: str
    status: FileStatus
    instances: int = 0          # files supplied (multi-instance families)
    multi_instance: bool = False
    required: bool = True


@dataclass(frozen=True, slots=True)
class Completion:
    """Overview of a project's data progress."""

    entries: tuple[CompletionEntry, ...]

    @property
    def expected(self) -> int:
        return sum(1 for e in self.entries if e.required)

    @property
    def supplied(self) -> int:
        return sum(1 for e in self.entries if e.required and e.status is FileStatus.VALID)

    @property
    def ratio(self) -> float:
        return round(self.supplied / self.expected, 4) if self.expected else 1.0

    def by_module(self) -> dict[str, dict[str, int]]:
        result: dict[str, dict[str, int]] = {}
        for entry in self.entries:
            counter = result.setdefault(entry.module, {"expected": 0, "supplied": 0})
            if entry.required:
                counter["expected"] += 1
                if entry.status is FileStatus.VALID:
                    counter["supplied"] += 1
        return result
