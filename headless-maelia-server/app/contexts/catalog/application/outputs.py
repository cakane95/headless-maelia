"""Output-catalog use cases.

The catalog says what the model *can* write; the launcher says what a scenario
*can reach*. Crossing the two is the job of this layer — neither repository can
answer it alone, and neither should have to know about the other.
"""

from collections.abc import Iterable, Mapping
from dataclasses import replace
from typing import Any, Protocol

from app.contexts.catalog.domain.models import OutputSpec, ParameterSpec
from app.contexts.catalog.domain.outputs import (
    Expectation,
    OutputReview,
    expectation,
    review,
)
from app.contexts.catalog.domain.services import (
    InvalidExpression,
    evaluate_condition,
    referenced_parameters,
)
from app.shared.errors import ConflictError, NotFoundError, ValidationError


class OutputRepository(Protocol):
    async def list_all(self) -> list[OutputSpec]: ...

    async def get(self, spec_id: str) -> OutputSpec | None: ...

    async def upsert(self, spec: OutputSpec) -> OutputSpec: ...

    async def delete(self, spec_id: str) -> bool: ...

    async def count(self) -> int: ...


async def list_outputs(
    repository: OutputRepository, module: str | None = None, theme: str | None = None
) -> list[OutputSpec]:
    specs = await repository.list_all()
    return [
        s
        for s in specs
        if (module is None or s.module == module) and (theme is None or s.theme == theme)
    ]


async def get_output(repository: OutputRepository, spec_id: str) -> OutputSpec:
    spec = await repository.get(spec_id)
    if spec is None:
        raise NotFoundError(f"sortie inconnue du catalogue : {spec_id}")
    return spec


def effective_values(
    values: Mapping[str, Any], parameters: Iterable[ParameterSpec]
) -> dict[str, Any]:
    """The values the model will see: the scenario's deltas over the defaults.

    An output guarded by a parameter nobody touched is still decided — by that
    parameter's default. Evaluating the guards on the deltas alone would report
    every output as absent.
    """
    complete = {spec.name: spec.default for spec in parameters}
    complete.update(values)
    return complete


def unreachable_terms(spec: OutputSpec, exposed: set[str]) -> list[str]:
    """Condition terms no scenario can act upon.

    Forty-one of the model's output switches are never declared by the launcher:
    they cannot be overridden in a `load`, so the output they command is out of
    reach whatever the user does. Saying so is the only honest answer to "why
    can't I turn this on?".
    """
    if not spec.produced_if:
        return []
    return [name for name in referenced_parameters(spec.produced_if) if name not in exposed]


async def expectations(
    outputs: OutputRepository,
    parameters: Iterable[ParameterSpec],
    values: Mapping[str, Any],
) -> list[tuple[OutputSpec, Expectation]]:
    """What a scenario holding these values would produce."""
    parameters = list(parameters)
    complete = effective_values(values, parameters)
    return [(spec, expectation(spec, complete)) for spec in await outputs.list_all()]


async def review_run(
    outputs: OutputRepository,
    parameters: Iterable[ParameterSpec],
    values: Mapping[str, Any],
    produced: Iterable[str],
) -> OutputReview:
    """Cross a finished run's files with what its settings asked for."""
    complete = effective_values(values, list(parameters))
    return review(await outputs.list_all(), complete, produced)


async def save_output(repository: OutputRepository, spec: OutputSpec) -> OutputSpec:
    """Create or update an output, after checking it can be used.

    Any manual write flips the origin to USER so the seed leaves it alone: the
    generator reruns on every model version bump and would otherwise silently
    undo the administrator's work.
    """
    issues = validate_output(spec)
    if issues:
        raise ValidationError(
            "sortie invalide : " + " ; ".join(f"{field} — {message}" for field, message in issues)
        )
    return await repository.upsert(replace(spec, origin="USER"))


def validate_output(spec: OutputSpec) -> list[tuple[str, str]]:
    """Refuse what the platform could store but never use."""
    issues: list[tuple[str, str]] = []

    if not spec.label.strip():
        issues.append(("label", "un libellé est nécessaire pour l'afficher"))
    if not spec.theme.strip():
        issues.append(("theme", "le thème regroupe les sorties, il est nécessaire"))
    if not spec.files:
        issues.append(("files", "une sortie sans fichier ne désigne rien"))
    for entry in spec.files:
        if "." not in entry.name:
            issues.append(("files", f"{entry.name} : un nom de fichier porte une extension"))

    if spec.produced_if:
        try:
            evaluate_condition(spec.produced_if, {})
        except InvalidExpression:
            issues.append((
                "produced_if",
                "condition illisible : forme attendue « paramètre == valeur », "
                "plusieurs conditions liées par && (et) ou || (ou)",
            ))
    return issues


async def delete_output(repository: OutputRepository, spec_id: str) -> None:
    spec = await repository.get(spec_id)
    if spec is None:
        raise NotFoundError(f"sortie inconnue du catalogue : {spec_id}")
    if spec.origin == "SEED":
        raise ConflictError(
            f"{spec_id} est écrite par le modèle : c'est un fait du GAML, "
            "pas une déclaration qu'on retire."
        )
    await repository.delete(spec_id)


async def restore_output(
    repository: OutputRepository, spec_id: str, reference: Iterable[OutputSpec]
) -> OutputSpec:
    """Revenir à ce que le modèle dit, et rendre la sortie au seed."""
    original = next((s for s in reference if s.id == spec_id), None)
    if original is None:
        raise NotFoundError(
            f"{spec_id} ne figure pas dans le catalogue de référence : "
            "elle a été ajoutée à la main, il n'y a rien à restaurer."
        )
    return await repository.upsert(original)
