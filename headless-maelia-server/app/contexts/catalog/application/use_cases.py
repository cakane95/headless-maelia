"""Catalog use cases.

Dependencies arrive as parameters: no concrete adapter is imported here.
"""

from typing import Any

from app.contexts.catalog.domain.models import DataSpec
from app.contexts.catalog.domain.ports import CatalogRepository
from app.contexts.catalog.domain.services import applicable_specs, order_by_dependencies
from app.shared.errors import ConflictError, NotFoundError


async def list_specs(repository: CatalogRepository, module: str | None = None) -> list[DataSpec]:
    specs = await repository.list_all()
    return [s for s in specs if module is None or s.module == module]


async def get_spec(repository: CatalogRepository, spec_id: str) -> DataSpec:
    spec = await repository.get(spec_id)
    if spec is None:
        raise NotFoundError(f"type de donnée inconnu : {spec_id}")
    return spec


async def list_applicable(
    repository: CatalogRepository, config: dict[str, Any]
) -> list[DataSpec]:
    """The files actually expected for a given modelling configuration."""
    return applicable_specs(await repository.list_all(), config)


async def dependency_graph(repository: CatalogRepository) -> dict[str, Any]:
    """Topological levels plus edges, for display and preprocessing."""
    specs = await repository.list_all()
    known = {s.id for s in specs}
    edges = [
        {"from": dependency, "to": s.id, "known": dependency in known}
        for s in specs
        for dependency in s.depends_on
    ]
    return {
        "levels": order_by_dependencies(specs),
        "edges": edges,
        "unknown_references": sorted({e["from"] for e in edges if not e["known"]}),
    }


async def save_spec(repository: CatalogRepository, spec: DataSpec) -> DataSpec:
    """Create or update a spec.

    Any manual write flips the origin to USER so the seed will not overwrite it.
    """
    return await repository.upsert(spec)


async def delete_spec(repository: CatalogRepository, spec_id: str) -> None:
    spec = await repository.get(spec_id)
    if spec is None:
        raise NotFoundError(f"type de donnée inconnu : {spec_id}")
    if spec.origin == "SEED":
        raise ConflictError(
            f"{spec_id} provient du catalogue de référence : il décrit un fichier "
            "que le modèle lit réellement et ne peut pas être supprimé."
        )
    await repository.delete(spec_id)
