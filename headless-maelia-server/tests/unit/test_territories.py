"""Order of the shipped territories.

The reference set has to come first: every caller that takes the first entry —
the project form among them — must land on the set proven to carry a run to the
end, not on whichever name sorts first alphabetically.
"""

import pytest

from app.contexts.project.infrastructure.repository import available_territories
from app.shared.config import settings


@pytest.fixture
def includes(tmp_path, monkeypatch):
    root = tmp_path / "includes"
    for name in ("includes_sasseme", "terrainTest", "autreZone", ".runs"):
        (root / name).mkdir(parents=True)
    (root / "readme.txt").write_text("pas un territoire", encoding="utf-8")
    monkeypatch.setattr(settings, "MAELIA_PROJECT_DIR", tmp_path)
    monkeypatch.setattr(settings, "MAELIA_DEFAULT_TERRITORY", "terrainTest")
    return root


def test_the_reference_set_comes_first(includes):
    assert available_territories()[0] == "terrainTest"


def test_the_others_follow_in_alphabetical_order(includes):
    assert available_territories() == ["terrainTest", "autreZone", "includes_sasseme"]


def test_working_copies_and_loose_files_are_not_territories(includes):
    """`.runs` holds the per-run copies; only directories count."""
    assert ".runs" not in available_territories()
    assert "readme.txt" not in available_territories()


def test_no_includes_directory_at_all(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "MAELIA_PROJECT_DIR", tmp_path)
    assert available_territories() == []
