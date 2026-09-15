"""What a run will write, given what the scenario sets.

MAELIA writes nothing by default. Every result module sits behind a boolean
switch, nested inside the guards of the modules it depends on — so the question
"why is this file missing?" has an answer in the model, and these rules read it.

Pure functions over `OutputSpec` and a flat map of parameter values: no session,
no file, no HTTP.
"""

from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from enum import StrEnum
from typing import Any

from app.contexts.catalog.domain.models import OutputSpec
from app.contexts.catalog.domain.services import (
    InvalidExpression,
    compared_parameter,
    evaluate_condition,
    referenced_parameters,
)


class Production(StrEnum):
    """Will the file be written?"""

    PRODUCED = "PRODUCED"
    ABSENT = "ABSENT"
    # The guard holds a term the condition language cannot express — a list
    # length, a call. Claiming either answer would be a guess.
    UNCERTAIN = "UNCERTAIN"


@dataclass(frozen=True, slots=True)
class Expectation:
    """One output, and what the current values do to it."""

    spec_id: str
    production: Production
    # Parameters to change to obtain the file, the shortest route first.
    blocking: tuple[str, ...] = ()
    reason: str = ""

    @property
    def expected(self) -> bool:
        return self.production is not Production.ABSENT


def _alternatives(expression: str) -> list[list[str]]:
    """The disjunctive normal form, as a list of conjunctions."""
    return [
        [term.strip() for term in alternative.split("&&") if term.strip()]
        for alternative in expression.split("||")
    ]


def _unmet(alternative: Iterable[str], values: Mapping[str, Any]) -> list[str]:
    """Parameters of this conjunction that do not currently hold."""
    failing: list[str] = []
    for term in alternative:
        name = compared_parameter(term)
        if name and not evaluate_condition(term, dict(values)):
            failing.append(name)
    return failing


def expectation(spec: OutputSpec, values: Mapping[str, Any]) -> Expectation:
    """Will this output be written, and if not, what stands in the way?"""
    if spec.unconditional:
        if spec.exact:
            return Expectation(spec.id, Production.PRODUCED, reason="écrite à chaque exécution")
        return Expectation(
            spec.id,
            Production.UNCERTAIN,
            reason="écrite hors aiguillage, sous une condition interne au modèle",
        )

    try:
        satisfied = evaluate_condition(spec.produced_if, dict(values))
    except InvalidExpression:
        # An unreadable condition must not hide an output, exactly as for inputs:
        # the problem stays visible instead of silently removing the file.
        return Expectation(
            spec.id,
            Production.UNCERTAIN,
            tuple(referenced_parameters(spec.produced_if or "")),
            "condition illisible : la sortie est peut-être écrite",
        )

    if satisfied and not spec.exact:
        return Expectation(
            spec.id,
            Production.UNCERTAIN,
            reason="une condition du modèle n'est pas exprimable ici — "
            "la sortie est probable, sans certitude",
        )
    if satisfied:
        return Expectation(spec.id, Production.PRODUCED, reason="toutes les conditions sont réunies")

    # Several routes may lead to the file; name the shortest, it is the advice
    # the user can act on.
    routes = sorted(
        (_unmet(alternative, values) for alternative in _alternatives(spec.produced_if)),
        key=len,
    )
    blocking = tuple(routes[0]) if routes else ()
    return Expectation(
        spec.id,
        Production.ABSENT,
        blocking,
        "à activer : " + ", ".join(blocking) if blocking else "condition non remplie",
    )


def expected_outputs(
    specs: Iterable[OutputSpec], values: Mapping[str, Any]
) -> list[Expectation]:
    return [expectation(spec, values) for spec in specs]


def owner(specs: Iterable[OutputSpec], file_name: str) -> OutputSpec | None:
    """Which declared output does this produced file belong to?"""
    return next((spec for spec in specs if spec.owns(file_name)), None)


@dataclass(frozen=True, slots=True)
class OutputReview:
    """A run's files, matched against what the catalog said to expect.

    `missing` is the interesting half: a file the scenario asked for and the run
    did not write points at the model, not at the user's settings.
    """

    produced: tuple[str, ...] = ()
    missing: tuple[str, ...] = ()
    undeclared: tuple[str, ...] = ()

    @property
    def complete(self) -> bool:
        return not self.missing


def review(
    specs: Iterable[OutputSpec], values: Mapping[str, Any], produced: Iterable[str]
) -> OutputReview:
    """Cross what was expected with what the run actually wrote."""
    specs = list(specs)
    written = list(produced)
    matched: set[str] = set()
    missing: list[str] = []

    for spec in specs:
        if expectation(spec, values).production is Production.ABSENT:
            continue
        for declared in spec.file_names:
            hits = [name for name in written if spec.owns(name) and _same_family(name, declared)]
            if hits:
                matched.update(hits)
            else:
                missing.append(declared)

    undeclared = [name for name in written if name not in matched and owner(specs, name) is None]
    return OutputReview(
        produced=tuple(sorted(matched)),
        missing=tuple(sorted(set(missing))),
        undeclared=tuple(sorted(undeclared)),
    )


def _same_family(produced_name: str, declared: str) -> bool:
    """Does this written file answer that declared name?

    A module declares `sorties_eau.csv` and writes `sorties_eau<suffixe>.csv`;
    two declared names of the same module must not both claim the same file.
    """
    if produced_name == declared:
        return True
    base, _, extension = declared.rpartition(".")
    return bool(base) and produced_name.startswith(base) and produced_name.endswith(f".{extension}")
