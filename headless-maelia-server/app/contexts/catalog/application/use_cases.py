"""Catalog use cases.

Dependencies arrive as parameters: no concrete adapter is imported here.
"""

from collections.abc import Iterable
from typing import Any

from app.contexts.catalog.domain.models import DataSpec, ParameterSpec
from app.contexts.catalog.domain.ports import CatalogRepository
from app.contexts.catalog.domain.services import (
    applicable_specs,
    order_by_dependencies,
    validate_parameter,
    validate_spec,
)
from app.shared.errors import ConflictError, NotFoundError, ValidationError


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
    """Create or update a spec, after checking it can actually be used.

    Any manual write flips the origin to USER so the seed will not overwrite it.
    """
    known = {s.id for s in await repository.list_all()}
    issues = validate_spec(spec, known)
    if issues:
        raise ValidationError(
            f"{spec.id} ne peut pas être enregistré",
            issues=[{"field": i.field, "message": i.message} for i in issues],
        )
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


async def restore_spec(
    repository: CatalogRepository, spec_id: str, reference: Iterable[DataSpec]
) -> DataSpec:
    """Put a hand-edited spec back to what the reference catalog says.

    Modifier une spec la bascule en USER, ce qui la protège du seed — et la fige
    donc sur une version du modèle. Sans ce retour en arrière, la seule issue
    serait de la supprimer et de redémarrer l'API.
    """
    original = next((s for s in reference if s.id == spec_id), None)
    if original is None:
        raise NotFoundError(
            f"{spec_id} ne figure pas dans le catalogue de référence : "
            "il a été ajouté à la main, il n'y a rien à restaurer."
        )
    return await repository.upsert(original)


# ── Paramètres de scénario ──────────────────────────────────────────────────

class ParameterCatalog:
    """Ce que ce module attend du catalogue de paramètres."""

    async def list_all(self) -> list[ParameterSpec]: ...
    async def get(self, name: str) -> ParameterSpec | None: ...
    async def upsert(self, spec: ParameterSpec) -> ParameterSpec: ...
    async def delete(self, name: str) -> None: ...


async def save_parameter(repository: ParameterCatalog, spec: ParameterSpec) -> ParameterSpec:
    """Créer ou modifier un paramètre, après avoir vérifié qu'il est servable.

    Toute écriture manuelle bascule l'origine en USER : le seed ne l'écrasera
    plus, et le paramètre cesse donc de suivre les montées de version du modèle.
    """
    connus = {p.name for p in await repository.list_all()}
    issues = validate_parameter(spec, connus)
    if issues:
        raise ValidationError(
            f"{spec.name} ne peut pas être enregistré",
            issues=[{"field": i.field, "message": i.message} for i in issues],
        )
    return await repository.upsert(spec)


async def delete_parameter(repository: ParameterCatalog, name: str) -> None:
    spec = await repository.get(name)
    if spec is None:
        raise NotFoundError(f"paramètre inconnu : {name}")
    if spec.origin == "SEED":
        raise ConflictError(
            f"{name} provient du launcher : c'est une variable que le modèle "
            "expose réellement, elle ne peut pas être supprimée."
        )
    await repository.delete(name)


async def restore_parameter(
    repository: ParameterCatalog, name: str, reference: Iterable[ParameterSpec]
) -> ParameterSpec:
    """Revenir à ce que le launcher déclare."""
    original = next((p for p in reference if p.name == name), None)
    if original is None:
        raise NotFoundError(
            f"{name} ne figure pas dans le catalogue de référence : "
            "il a été ajouté à la main, il n'y a rien à restaurer."
        )
    return await repository.upsert(original)
