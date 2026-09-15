"""Creating a project: what the user supplies, and what the platform decides.

The territory is not a user choice. It remains a technical name the run needs —
`nomDecoupageZonePourLectureFichiers` — so it is still accepted and still
checked when supplied, by the test bench and by these tests.
"""

import uuid

import pytest

from app.contexts.project.application.use_cases import create_project
from app.contexts.project.domain.models import Project
from app.shared.errors import ValidationError

SHIPPED = ["terrainTest", "includes_sasseme"]


class FakeProjects:
    """Keeps what it is handed: enough to read back what was decided."""

    def __init__(self) -> None:
        self.saved: list[Project] = []

    async def save(self, project: Project) -> Project:
        self.saved.append(project)
        return project

    async def get(self, project_id: uuid.UUID) -> Project | None:
        return next((p for p in self.saved if p.id == project_id), None)


async def test_a_name_is_enough():
    project = await create_project(FakeProjects(), name="Garonne", valid_territories=SHIPPED)
    assert project.name == "Garonne"


async def test_the_reference_set_is_taken_when_none_is_given():
    """The first entry is the reference set — the list comes back ordered."""
    project = await create_project(FakeProjects(), name="Garonne", valid_territories=SHIPPED)
    assert project.territory == "terrainTest"


async def test_an_explicit_territory_is_still_honoured():
    """The test bench runs on a chosen set; that path must keep working."""
    project = await create_project(
        FakeProjects(), name="Essai", valid_territories=SHIPPED, territory="includes_sasseme"
    )
    assert project.territory == "includes_sasseme"


async def test_an_unknown_territory_is_refused_at_creation():
    """Otherwise it would only surface when launching a run, screens later."""
    with pytest.raises(ValidationError, match="territoire inconnu"):
        await create_project(
            FakeProjects(), name="Essai", valid_territories=SHIPPED, territory="ailleurs"
        )


async def test_no_shipped_set_at_all_does_not_block_creation():
    """The shared volume may not be mounted yet: the run will say so, not the form."""
    project = await create_project(FakeProjects(), name="Garonne", valid_territories=[])
    assert project.territory
