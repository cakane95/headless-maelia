"""Scenario use cases."""

import uuid
from typing import Any

from app.contexts.catalog.domain.models import ParameterSpec
from app.contexts.dataset.domain.ports import DatasetRepository
from app.contexts.scenario.domain.models import Scenario
from app.contexts.scenario.domain.ports import ScenarioRepository
from app.contexts.scenario.domain.services import ParameterIssue, validate_parameters
from app.shared.errors import NotFoundError, ValidationError


class ParameterRepository:
    """Structural type of what this context needs from the parameter catalog."""

    async def list_all(self) -> list[ParameterSpec]: ...


async def list_scenarios(
    repository: ScenarioRepository, project_id: uuid.UUID
) -> list[Scenario]:
    return await repository.list_for_project(project_id)


async def get_scenario(repository: ScenarioRepository, scenario_id: uuid.UUID) -> Scenario:
    scenario = await repository.get(scenario_id)
    if scenario is None:
        raise NotFoundError(f"scénario inconnu : {scenario_id}")
    return scenario


async def create_scenario(
    scenarios: ScenarioRepository,
    parameters: ParameterRepository,
    datasets: DatasetRepository,
    project_id: uuid.UUID,
    name: str,
    description: str | None = None,
    parameter_values: dict[str, Any] | None = None,
    dataset_pins: dict[str, str] | None = None,
) -> Scenario:
    await _check_parameters(parameters, parameter_values or {})
    await _check_pins(datasets, project_id, dataset_pins or {})
    return await scenarios.save(
        Scenario.create(project_id, name, description, parameter_values, dataset_pins)
    )


async def update_scenario(
    scenarios: ScenarioRepository,
    parameters: ParameterRepository,
    datasets: DatasetRepository,
    scenario_id: uuid.UUID,
    name: str | None = None,
    description: str | None = None,
    parameter_values: dict[str, Any] | None = None,
    dataset_pins: dict[str, str] | None = None,
) -> Scenario:
    from dataclasses import replace

    scenario = await get_scenario(scenarios, scenario_id)

    if parameter_values is not None:
        await _check_parameters(parameters, parameter_values)
        scenario = scenario.with_parameters(parameter_values)
    if dataset_pins is not None:
        await _check_pins(datasets, scenario.project_id, dataset_pins)
        scenario = scenario.with_pins(dataset_pins)

    scenario = replace(
        scenario,
        name=name if name is not None else scenario.name,
        description=description if description is not None else scenario.description,
    )
    return await scenarios.save(scenario)


async def delete_scenario(repository: ScenarioRepository, scenario_id: uuid.UUID) -> None:
    await get_scenario(repository, scenario_id)
    await repository.delete(scenario_id)


async def _check_parameters(
    parameters: ParameterRepository, values: dict[str, Any]
) -> None:
    if not values:
        return
    issues: list[ParameterIssue] = validate_parameters(values, await parameters.list_all())
    if issues:
        raise ValidationError(
            "paramètres invalides",
            issues=[{"field": i.parameter, "message": i.message} for i in issues],
        )


async def _check_pins(
    datasets: DatasetRepository, project_id: uuid.UUID, pins: dict[str, str]
) -> None:
    """A pinned version must belong to a dataset of this project.

    Without this check a scenario could point at another project's version, and
    the run would materialise data nobody expected.
    """
    if not pins:
        return

    by_id = {str(d.id): d for d in await datasets.list_for_project(project_id)}
    issues: list[dict[str, str]] = []

    for dataset_id, version_id in pins.items():
        dataset = by_id.get(str(dataset_id))
        if dataset is None:
            issues.append({
                "field": str(dataset_id),
                "message": "ce jeu de données n'appartient pas au projet",
            })
            continue
        try:
            found = dataset.version(uuid.UUID(str(version_id)))
        except ValueError:
            found = None
        if found is None:
            issues.append({
                "field": str(dataset_id),
                "message": f"version {version_id} introuvable pour {dataset.data_spec_id}",
            })

    if issues:
        raise ValidationError("versions épinglées invalides", issues=issues)
