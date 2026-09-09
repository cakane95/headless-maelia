"""Project domain: completion and configuration, without infrastructure."""

from app.contexts.catalog.domain.models import DataSpec, FileKind
from app.contexts.project.domain.models import (
    DEFAULT_CONFIGURATION,
    FileStatus,
    Project,
)
from app.contexts.project.domain.services import compute_completion, missing_files


def spec(spec_id: str, module: str = "modeleAgricole", **kw) -> DataSpec:
    base = dict(id=spec_id, label=spec_id, module=module, kind=FileKind.CSV,
                relative_dir=module, file_name="x.csv")
    return DataSpec(**{**base, **kw})


# ── Configuration ───────────────────────────────────────────────────────────

def test_new_project_starts_from_launcher_defaults():
    project = Project.create(name="Garonne", territory="terrainTest")
    assert project.modeling_config == DEFAULT_CONFIGURATION
    assert project.modeling_config["nomChoixAssolement"] == "Donnees"


def test_partial_update_does_not_reset_the_rest():
    project = Project.create(name="G", territory="terrainTest")
    updated = project.with_configuration({"executerModeleHydrographique": True})
    assert updated.modeling_config["executerModeleHydrographique"] is True
    # Everything else keeps its value, it does not fall back to the default.
    assert updated.modeling_config["nomChoixAssolement"] == "Donnees"


# ── Completion ──────────────────────────────────────────────────────────────

def test_without_data_everything_is_missing():
    completion = compute_completion([spec("a"), spec("b")], {})
    assert completion.expected == 2
    assert completion.supplied == 0
    assert completion.ratio == 0.0
    assert all(e.status is FileStatus.MISSING for e in completion.entries)


def test_ratio_and_missing_files():
    inventory = {"a": {"": FileStatus.VALID}}
    completion = compute_completion([spec("a"), spec("b")], inventory)
    assert completion.supplied == 1
    assert completion.ratio == 0.5
    assert missing_files(completion) == ["b"]


def test_one_invalid_file_invalidates_the_family():
    """The model reads every file of a family: a single bad one is enough."""
    weather = spec("meteo", file_name=None, file_name_pattern=r"\d{4}\.csv")
    inventory = {"meteo": {
        "2018.csv": FileStatus.VALID,
        "2019.csv": FileStatus.INVALID,
    }}
    completion = compute_completion([weather], inventory)
    entry = completion.entries[0]
    assert entry.status is FileStatus.INVALID
    assert entry.instances == 2
    assert entry.multi_instance


def test_draft_does_not_count_as_supplied():
    inventory = {"a": {"": FileStatus.DRAFT}}
    completion = compute_completion([spec("a")], inventory)
    assert completion.supplied == 0
    assert missing_files(completion) == ["a"]


def test_optional_file_is_out_of_the_count():
    completion = compute_completion([spec("a"), spec("b", required=False)], {})
    assert completion.expected == 1
    assert missing_files(completion) == ["a"]


def test_breakdown_by_module():
    inventory = {"a": {"": FileStatus.VALID}}
    completion = compute_completion(
        [spec("a"), spec("b"), spec("c", module="modeleCommun")], inventory
    )
    assert completion.by_module() == {
        "modeleAgricole": {"expected": 2, "supplied": 1},
        "modeleCommun": {"expected": 1, "supplied": 0},
    }
