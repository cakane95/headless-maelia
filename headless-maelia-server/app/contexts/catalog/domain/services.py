"""Catalog business rules — pure functions, testable without infrastructure."""

import re
from collections.abc import Iterable, Sequence
from typing import Any

from app.contexts.catalog.domain.models import DataSpec

# `required_if` is a deliberately minimal expression: `<param> <op> <literal>`.
# Arbitrary code is never evaluated — the catalog is data, not script.
_COMPARISON = re.compile(
    r"^\s*(?P<param>[A-Za-z_][\w]*)\s*(?P<op>==|!=)\s*(?P<value>'[^']*'|\"[^\"]*\"|[\w.\-]+)\s*$"
)


class InvalidExpression(ValueError):
    """`required_if` does not follow the expected form."""


def _literal(raw: str) -> Any:
    raw = raw.strip()
    if raw[:1] in {"'", '"'}:
        return raw[1:-1]
    if raw == "true":
        return True
    if raw == "false":
        return False
    try:
        return int(raw)
    except ValueError:
        pass
    try:
        return float(raw)
    except ValueError:
        return raw


def evaluate_condition(expression: str, config: dict[str, Any]) -> bool:
    """Evaluate an applicability condition against the project configuration.

    Accepted form: one or more `param == value` / `param != value` comparisons
    joined by `&&` — all must hold. This is deliberately the useful minimum: a
    hydrographic file in SWAT mode reads
    `executerModeleHydrographique == true && nomChoixModeleHydrographique == 'SWAT'`.
    No `||`, no parentheses: no real case needs them, and the condition must stay
    readable by an administrator.

    A parameter missing from the configuration counts as unset: an equality is
    then false, an inequality true.
    """
    if "&&" in expression:
        return all(evaluate_condition(part, config) for part in expression.split("&&"))

    match = _COMPARISON.match(expression)
    if match is None:
        raise InvalidExpression(f"unrecognised condition: {expression!r}")

    expected = _literal(match["value"])
    current = config.get(match["param"])

    # The front end may send booleans as text: align before comparing.
    if isinstance(expected, bool) and isinstance(current, str):
        current = current.lower() == "true"

    return current == expected if match["op"] == "==" else current != expected


def is_applicable(spec: DataSpec, config: dict[str, Any]) -> bool:
    """Is this file expected, given the project configuration?

    With no condition a file always applies. An unreadable condition must not
    hide a file: it is treated as applicable so the problem stays visible.
    """
    if not spec.required_if:
        return True
    try:
        return evaluate_condition(spec.required_if, config)
    except InvalidExpression:
        return True


def applicable_specs(specs: Iterable[DataSpec], config: dict[str, Any]) -> list[DataSpec]:
    return [s for s in specs if is_applicable(s, config)]


def matches_instance(spec: DataSpec, file_name: str) -> bool:
    """Does this file name belong to that multi-instance family?

    Used by bulk import: a ZIP of files is filed into the right datasets without
    asking the user to name them.
    """
    if spec.file_name is not None:
        return file_name == spec.file_name
    if not spec.file_name_pattern:
        return False
    return re.fullmatch(spec.file_name_pattern, file_name) is not None


def resolve_spec(specs: Sequence[DataSpec], file_name: str) -> DataSpec | None:
    """Find the spec matching a file name.

    Exact matches win over patterns: `canaux.csv` must land on its own spec, not
    on the "one file per canal" family.
    """
    for spec in specs:
        if spec.file_name == file_name:
            return spec
    for spec in specs:
        if matches_instance(spec, file_name):
            return spec
    return None


def order_by_dependencies(specs: Sequence[DataSpec]) -> list[list[str]]:
    """Group specs in levels: a level depends only on the previous ones.

    Feeds the preprocessing module (which file to produce before which) and the
    graph view. Any cycle is returned as a last level rather than failing the call.
    """
    known = {s.id for s in specs}
    remaining = {s.id: {d for d in s.depends_on if d in known} for s in specs}
    levels: list[list[str]] = []

    while remaining:
        ready = sorted(spec_id for spec_id, deps in remaining.items() if not deps)
        if not ready:  # cycle: return the rest as is rather than looping forever
            levels.append(sorted(remaining))
            break
        levels.append(ready)
        for spec_id in ready:
            del remaining[spec_id]
        for deps in remaining.values():
            deps.difference_update(ready)

    return levels
