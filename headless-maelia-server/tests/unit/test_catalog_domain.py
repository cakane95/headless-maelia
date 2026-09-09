"""Catalog domain: no infrastructure, therefore no containers."""

import pytest

from app.contexts.catalog.domain.models import DataSpec, FieldSpec, FieldType, FileKind
from app.contexts.catalog.domain.services import (
    evaluate_condition,
    is_applicable,
    matches_instance,
    order_by_dependencies,
    resolve_spec,
)


def spec(**kw) -> DataSpec:
    base = dict(id="x", label="x", module="modeleAgricole", kind=FileKind.CSV,
                relative_dir="modeleAgricole", file_name="x.csv")
    return DataSpec(**{**base, **kw})


# ── required_if ─────────────────────────────────────────────────────────────

@pytest.mark.parametrize(
    ("expression", "config", "expected"),
    [
        ("executerModeleHydrographique == true", {"executerModeleHydrographique": True}, True),
        ("executerModeleHydrographique == true", {"executerModeleHydrographique": False}, False),
        # The front end sometimes sends booleans as text.
        ("executerModeleHydrographique == true", {"executerModeleHydrographique": "true"}, True),
        ("nomChoixModeleHydrographique == 'SWAT'", {"nomChoixModeleHydrographique": "SWAT"}, True),
        ("nomChoixModeleHydrographique == 'SWAT'",
         {"nomChoixModeleHydrographique": "Simple"}, False),
        ("nomScenarioClimatique != ''", {"nomScenarioClimatique": "rcp8.5"}, True),
        ("nomScenarioClimatique != ''", {"nomScenarioClimatique": ""}, False),
        # Missing parameter: equality is false, inequality true.
        ("executerBarrage == true", {}, False),
    ],
)
def test_evaluate_condition(expression, config, expected):
    assert evaluate_condition(expression, config) is expected


def test_conjunction_requires_every_part():
    """A file-level condition REFINES the module one, it does not replace it."""
    swat = "executerModeleHydrographique == true && nomChoixModeleHydrographique == 'SWAT'"
    assert evaluate_condition(swat, {
        "executerModeleHydrographique": True, "nomChoixModeleHydrographique": "SWAT"}) is True
    # Module switched off: the file is not expected, even in SWAT mode.
    assert evaluate_condition(swat, {
        "executerModeleHydrographique": False, "nomChoixModeleHydrographique": "SWAT"}) is False
    assert evaluate_condition(swat, {
        "executerModeleHydrographique": True, "nomChoixModeleHydrographique": "Simple"}) is False


def test_no_condition_means_always_applicable():
    assert is_applicable(spec(), {}) is True


def test_unreadable_condition_does_not_hide_the_file():
    """Better a file wrongly asked for than a file silently forgotten."""
    assert is_applicable(spec(required_if="this is not a condition"), {}) is True


# ── multi-instance ──────────────────────────────────────────────────────────

def test_matches_instance_by_pattern():
    weather = spec(id="commun.meteo.observee", file_name=None, file_name_pattern=r"\d{4}\.csv")
    assert weather.multi_instance
    assert matches_instance(weather, "2018.csv")
    assert not matches_instance(weather, "polygones.csv")


def test_exact_match_wins_over_pattern():
    canals = spec(id="hydro.canaux.canaux", file_name="canaux.csv")
    detail = spec(id="hydro.canaux.detail", file_name=None,
                  file_name_pattern=r"(?!canaux\.csv).+\.csv")
    assert resolve_spec([detail, canals], "canaux.csv").id == "hydro.canaux.canaux"
    assert resolve_spec([detail, canals], "canalNord.csv").id == "hydro.canaux.detail"


def test_target_path():
    fixed = spec(relative_dir="modeleAgricole/culture", file_name="especesCultivees.csv")
    assert fixed.target_path() == "modeleAgricole/culture/especesCultivees.csv"

    weather = spec(relative_dir="modeleCommun/meteo/observee", file_name=None)
    assert weather.target_path("2018.csv") == "modeleCommun/meteo/observee/2018.csv"
    with pytest.raises(ValueError):
        weather.target_path()


# ── field typing ────────────────────────────────────────────────────────────

def test_na_is_a_missing_value_not_an_error():
    """MAELIA writes a literal "NA": that is not a typing failure."""
    field = FieldSpec(name="RENDEMENT_MOYEN", type=FieldType.FLOAT)
    assert field.accepts("NA")
    assert field.accepts("[NA]")
    assert field.accepts("2.8")
    assert not field.accepts("beaucoup")


def test_comma_decimal_accepted():
    assert FieldSpec(name="x", type=FieldType.FLOAT).accepts("2,8")


def test_required_field_rejects_blank():
    assert not FieldSpec(name="ID", required=True).accepts("")


# ── dependency graph ────────────────────────────────────────────────────────

def test_levels_follow_dependencies():
    zh = spec(id="hydro.ZH", depends_on=())
    soil = spec(id="commun.sol", depends_on=("hydro.ZH",))
    plots = spec(id="agri.ilots", depends_on=("hydro.ZH", "commun.sol"))
    assert order_by_dependencies([plots, soil, zh]) == [
        ["hydro.ZH"], ["commun.sol"], ["agri.ilots"]
    ]


def test_cycle_does_not_loop_forever():
    a = spec(id="a", depends_on=("b",))
    b = spec(id="b", depends_on=("a",))
    assert order_by_dependencies([a, b]) == [["a", "b"]]
