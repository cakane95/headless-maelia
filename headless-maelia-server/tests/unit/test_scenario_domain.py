"""Scenario domain: parameter deltas and version pins, without infrastructure."""

import uuid

from app.contexts.catalog.domain.models import ParameterSpec, ParameterType
from app.contexts.scenario.domain.models import Scenario
from app.contexts.scenario.domain.services import (
    effective_parameters,
    grouped,
    validate_parameters,
)


def spec(name: str, kind: ParameterType, **kw) -> ParameterSpec:
    base = dict(name=name, label=name, group="Général", type=kind)
    return ParameterSpec(**{**base, **kw})


CATALOG = [
    spec("nbAnneesSimulation", ParameterType.INT, default=3),
    spec("executerModeleHydrographique", ParameterType.BOOL, default=False),
    spec("nomChoixAssolement", ParameterType.STRING, default="Donnees"),
    spec("coefficientManningTerrain", ParameterType.FLOAT, default=0.12),
    spec("listNomsZHsDecoupageZone", ParameterType.LIST, default=[]),
    spec("idSimulationAPI", ParameterType.STRING, system=True, editable=False),
    spec("cheminRacineMaelia", ParameterType.EXPRESSION, editable=False),
]


# ── Parameter validation ────────────────────────────────────────────────────

def test_valid_deltas_pass():
    assert validate_parameters(
        {"nbAnneesSimulation": 1, "executerModeleHydrographique": True}, CATALOG
    ) == []


def test_unknown_parameter_is_refused():
    """GAMA would silently ignore it — better to say so."""
    issues = validate_parameters({"nExistePas": 1}, CATALOG)
    assert len(issues) == 1
    assert "inconnu du launcher" in issues[0].message


def test_system_parameter_is_refused():
    """The worker overrides it: setting it would change nothing."""
    issues = validate_parameters({"idSimulationAPI": "abc"}, CATALOG)
    assert "piloté par la plateforme" in issues[0].message


def test_expression_parameter_is_refused():
    issues = validate_parameters({"cheminRacineMaelia": "/x"}, CATALOG)
    assert "non modifiable" in issues[0].message


def test_wrong_type_is_located():
    issues = validate_parameters({"nbAnneesSimulation": "trois"}, CATALOG)
    assert issues[0].parameter == "nbAnneesSimulation"
    assert "int valide" in issues[0].message


def test_boolean_is_not_an_integer():
    """`bool` is an `int` in Python: True must not pass for 1."""
    assert validate_parameters({"nbAnneesSimulation": True}, CATALOG)


def test_integer_is_accepted_for_a_float():
    assert validate_parameters({"coefficientManningTerrain": 1}, CATALOG) == []


def test_allowed_values_are_enforced():
    constrained = [spec("mode", ParameterType.STRING, allowed_values=("SWAT", "Simple"))]
    assert validate_parameters({"mode": "SWAT"}, constrained) == []
    assert validate_parameters({"mode": "AUTRE"}, constrained)


# ── gama-server payload ─────────────────────────────────────────────────────

def test_payload_carries_only_the_deltas():
    """An unset parameter keeps the launcher default — which survives a model upgrade."""
    payload = effective_parameters({"nbAnneesSimulation": 1}, CATALOG)
    assert payload == [{"type": "int", "name": "nbAnneesSimulation", "value": 1}]


def test_system_parameters_never_reach_gama_from_a_scenario():
    """The worker adds them itself; a scenario must not compete with it."""
    assert effective_parameters({"idSimulationAPI": "abc"}, CATALOG) == []


def test_types_are_translated_for_gama():
    payload = effective_parameters(
        {"executerModeleHydrographique": True, "listNomsZHsDecoupageZone": ["A"]}, CATALOG
    )
    assert {p["name"]: p["type"] for p in payload} == {
        "executerModeleHydrographique": "bool",
        "listNomsZHsDecoupageZone": "list",
    }


def test_grouping_follows_the_launcher_sections():
    catalog = [
        spec("a", ParameterType.BOOL, group="Général"),
        spec("b", ParameterType.BOOL, group="Sorties"),
        spec("c", ParameterType.BOOL, group="Général"),
    ]
    assert {k: [s.name for s in v] for k, v in grouped(catalog).items()} == {
        "Général": ["a", "c"], "Sorties": ["b"]
    }


# ── Pins ────────────────────────────────────────────────────────────────────

def test_pin_and_unpin():
    dataset_id, version_id = uuid.uuid4(), uuid.uuid4()
    scenario = Scenario.create(uuid.uuid4(), "A")
    assert scenario.dataset_pins == {}

    pinned = scenario.pin(dataset_id, version_id)
    assert pinned.dataset_pins == {str(dataset_id): str(version_id)}

    # Unpinning lets the dataset follow its latest valid version again.
    assert pinned.unpin(dataset_id).dataset_pins == {}


def test_replacing_parameters_allows_removing_an_override():
    """A merge would make it impossible to go back to a default."""
    scenario = Scenario.create(uuid.uuid4(), "A", parameter_values={"a": 1, "b": 2})
    assert scenario.with_parameters({"a": 1}).parameter_values == {"a": 1}


def test_pins_are_stored_as_strings():
    """JSONB keys are text: normalising at the boundary avoids lookup misses."""
    dataset_id, version_id = uuid.uuid4(), uuid.uuid4()
    scenario = Scenario.create(uuid.uuid4(), "A", dataset_pins={dataset_id: version_id})
    assert scenario.dataset_pins == {str(dataset_id): str(version_id)}
