"""Scenario domain model — pure.

A scenario holds what makes a run *different*: the parameter deltas from the
launcher defaults, and the data versions it pins.

Two deliberate choices:

* **Deltas only.** Storing the 148 parameters would freeze the launcher defaults
  at creation time; a model upgrade would then silently keep obsolete values.
* **Pin only what must vary.** Anything unpinned follows its dataset's latest
  valid version, so a scenario stays useful as data is corrected.
"""

import uuid
from dataclasses import dataclass, field, replace
from datetime import datetime
from typing import Any


@dataclass(frozen=True, slots=True)
class Scenario:
    id: uuid.UUID
    project_id: uuid.UUID
    name: str
    description: str | None = None
    # Deltas from the launcher defaults: {parameter name: value}.
    parameter_values: dict[str, Any] = field(default_factory=dict)
    # Pinned versions: {dataset_id: version_id}.
    dataset_pins: dict[str, str] = field(default_factory=dict)
    created_at: datetime | None = None
    updated_at: datetime | None = None

    @staticmethod
    def create(
        project_id: uuid.UUID,
        name: str,
        description: str | None = None,
        parameter_values: dict[str, Any] | None = None,
        dataset_pins: dict[str, str] | None = None,
    ) -> "Scenario":
        return Scenario(
            id=uuid.uuid4(),
            project_id=project_id,
            name=name,
            description=description,
            parameter_values=dict(parameter_values or {}),
            dataset_pins={str(k): str(v) for k, v in (dataset_pins or {}).items()},
        )

    def with_parameters(self, values: dict[str, Any]) -> "Scenario":
        """Replace the deltas wholesale.

        A merge would make removing an override impossible: sending the full set
        is the only way to say "this parameter goes back to its default".
        """
        return replace(self, parameter_values=dict(values))

    def with_pins(self, pins: dict[str, str]) -> "Scenario":
        return replace(self, dataset_pins={str(k): str(v) for k, v in pins.items()})

    def pin(self, dataset_id: uuid.UUID, version_id: uuid.UUID) -> "Scenario":
        return replace(
            self, dataset_pins={**self.dataset_pins, str(dataset_id): str(version_id)}
        )

    def unpin(self, dataset_id: uuid.UUID) -> "Scenario":
        """Let this dataset follow its latest valid version again."""
        pins = {k: v for k, v in self.dataset_pins.items() if k != str(dataset_id)}
        return replace(self, dataset_pins=pins)
