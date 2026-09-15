"""Scenario rules — pure functions."""

from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from typing import Any

from app.contexts.catalog.domain.models import ParameterSpec


@dataclass(frozen=True, slots=True)
class ParameterIssue:
    parameter: str
    message: str


def validate_parameters(
    values: Mapping[str, Any], specs: Iterable[ParameterSpec]
) -> list[ParameterIssue]:
    """Check the deltas against the parameter catalog.

    Three refusals, each with a reason the user can act on:
      - unknown name: the launcher does not expose it, GAMA would ignore it;
      - system parameter: the worker overrides it, setting it changes nothing;
      - wrong type: gama-server would reject the `load`.
    """
    by_name = {s.name: s for s in specs}
    issues: list[ParameterIssue] = []

    for name, value in values.items():
        spec = by_name.get(name)
        if spec is None:
            issues.append(ParameterIssue(
                name, "paramètre inconnu du launcher : il serait ignoré par GAMA"
            ))
            continue
        if spec.system:
            issues.append(ParameterIssue(
                name, "paramètre piloté par la plateforme : le fixer n'aurait aucun effet"
            ))
            continue
        if not spec.editable:
            issues.append(ParameterIssue(
                name, "paramètre non modifiable : sa valeur par défaut est une expression"
            ))
            continue
        if not spec.accepts(value):
            expected = spec.type.value.lower()
            issues.append(ParameterIssue(
                name, f"« {value} » n'est pas un {expected} valide"
            ))

    return issues


def effective_parameters(
    values: Mapping[str, Any], specs: Iterable[ParameterSpec]
) -> list[dict[str, Any]]:
    """Turn the deltas into the payload gama-server expects at `load`.

    Deux choses voyagent, et seulement deux.

    **Les ecarts du scenario.** Un parametre qu'il ne fixe pas garde la valeur
    du modele, ce qui est exactement ce qu'on veut quand le modele monte de
    version : le scenario ne fige que ce qu'il a voulu figer.

    **Les defauts que le catalogue impose.** Le catalogue tient ses valeurs par
    defaut du launcher de reference, qui n'est pas celui qu'on execute. Quand
    les deux divergent, ne rien envoyer ferait mentir la plateforme : elle
    afficherait une valeur et GAMA en appliquerait une autre. On envoie donc la
    valeur annoncee, et le scenario reste prioritaire sur elle.
    """
    specs = list(specs)
    by_name = {s.name: s for s in specs}
    payload: list[dict[str, Any]] = []

    for spec in specs:
        if spec.system or not spec.imposed or spec.name in values:
            continue
        payload.append({
            "type": spec.gama_type(), "name": spec.name, "value": spec.default
        })

    for name, value in values.items():
        spec = by_name.get(name)
        if spec is None or spec.system:
            continue
        payload.append({"type": spec.gama_type(), "name": name, "value": value})

    return payload


def grouped(specs: Iterable[ParameterSpec]) -> dict[str, list[ParameterSpec]]:
    """Parameters by launcher section, for the editing screen."""
    result: dict[str, list[ParameterSpec]] = {}
    for spec in specs:
        result.setdefault(spec.group, []).append(spec)
    return result
