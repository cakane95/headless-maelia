"""Project use cases."""

import uuid
from dataclasses import replace
from typing import Any

from app.contexts.catalog.domain.ports import CatalogRepository
from app.contexts.catalog.domain.services import applicable_specs
from app.contexts.project.domain.models import Completion, Project
from app.contexts.project.domain.ports import DatasetInventoryPort, ProjectRepository
from app.contexts.project.domain.services import compute_completion
from app.shared.config import settings
from app.shared.errors import NotFoundError, ValidationError

# Repli quand le volume partagé n'expose aucun territoire : le run échouera à la
# matérialisation, avec un message clair, plutôt qu'à la création sur un champ
# que personne n'a rempli.
DEFAULT_TERRITORY = settings.MAELIA_DEFAULT_TERRITORY


async def list_projects(repository: ProjectRepository) -> list[Project]:
    return await repository.list_all()


async def get_project(repository: ProjectRepository, project_id: uuid.UUID) -> Project:
    project = await repository.get(project_id)
    if project is None:
        raise NotFoundError(f"projet inconnu : {project_id}")
    return project


async def create_project(
    repository: ProjectRepository,
    name: str,
    valid_territories: list[str],
    territory: str | None = None,
    description: str | None = None,
    modeling_config: dict[str, Any] | None = None,
) -> Project:
    """Create a project. The territory is not a choice the user makes.

    Every project starts from the reference data set and overlays its own files
    onto it; `nomDecoupageZonePourLectureFichiers` remains a technical name the
    run needs, not a decision. It stays accepted as a parameter for the test
    bench and for tests — and is then checked, because an unknown territory
    would otherwise only surface when launching a run, several screens later.
    """
    chosen = territory or (valid_territories[0] if valid_territories else DEFAULT_TERRITORY)
    if territory and valid_territories and territory not in valid_territories:
        raise ValidationError(
            f"territoire inconnu : {territory}. Disponibles : {', '.join(valid_territories)}"
        )
    return await repository.save(Project.create(name, chosen, description, modeling_config))


async def update_project(
    repository: ProjectRepository,
    project_id: uuid.UUID,
    name: str | None = None,
    description: str | None = None,
) -> Project:
    project = await get_project(repository, project_id)
    return await repository.save(
        replace(
            project,
            name=name if name is not None else project.name,
            description=description if description is not None else project.description,
        )
    )


async def update_configuration(
    repository: ProjectRepository, project_id: uuid.UUID, config: dict[str, Any]
) -> Project:
    """Update the modelling configuration.

    It changes the list of expected files: this is the lever that makes a module
    (hydrographic, normative, livestock) required or not.
    """
    project = await get_project(repository, project_id)
    return await repository.save(project.with_configuration(config))


async def delete_project(repository: ProjectRepository, project_id: uuid.UUID) -> None:
    await get_project(repository, project_id)
    await repository.delete(project_id)


async def project_completion(
    projects: ProjectRepository,
    catalog: CatalogRepository,
    inventory: DatasetInventoryPort,
    project_id: uuid.UUID,
) -> tuple[Project, Completion]:
    """Cross the files expected by the configuration with the data supplied."""
    project = await get_project(projects, project_id)
    applicable = applicable_specs(await catalog.list_all(), project.modeling_config)
    state = await inventory.inventory(project_id)
    return project, compute_completion(applicable, state)
