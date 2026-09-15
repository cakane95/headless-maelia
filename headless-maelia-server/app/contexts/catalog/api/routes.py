"""Input catalog routes — ADMINISTRATION domain.

Reads are open (the simulation domain needs them); writes sit under the `/admin`
prefix.
"""

from typing import Annotated, Any

from fastapi import APIRouter, Body, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.contexts.catalog.application import use_cases
from app.contexts.catalog.domain.models import (
    DataSpec,
    FieldSpec,
    FieldType,
    FileKind,
    Orientation,
    ParameterSpec,
    ParameterType,
)
from app.contexts.catalog.infrastructure.repository import (
    SqlCatalogRepository,
    SqlParameterRepository,
)
from app.contexts.catalog.infrastructure.seed import load_parameter_seed, load_seed
from app.shared.database import get_session
from app.shared.errors import NotFoundError

router = APIRouter(prefix="/api/v1", tags=["input catalog"])


def repository(session: Annotated[AsyncSession, Depends(get_session)]) -> SqlCatalogRepository:
    return SqlCatalogRepository(session)


Repo = Annotated[SqlCatalogRepository, Depends(repository)]


def parameter_repository(
    session: Annotated[AsyncSession, Depends(get_session)],
) -> SqlParameterRepository:
    return SqlParameterRepository(session)


Parameters = Annotated[SqlParameterRepository, Depends(parameter_repository)]
Session = Annotated[AsyncSession, Depends(get_session)]


# ── HTTP schemas (distinct from the domain) ─────────────────────────────────

class FieldSpecOut(BaseModel):
    name: str
    label: str | None = None
    type: FieldType = FieldType.STRING
    required: bool = False
    unit: str | None = None
    allowed_values: list[str] = Field(default_factory=list)
    references_data_spec: str | None = None
    position: int = 0


class DataSpecOut(BaseModel):
    id: str
    label: str
    module: str
    kind: FileKind
    relative_dir: str
    file_name: str | None
    file_name_pattern: str | None
    orientation: Orientation | None
    delimiter: str
    has_header: bool
    matrix_value_start_index: int | None
    required: bool
    required_if: str | None
    depends_on: list[str]
    gaml_source: str | None
    origin: str
    multi_instance: bool
    fields: list[FieldSpecOut]


class DataSpecIn(BaseModel):
    label: str
    module: str
    kind: FileKind = FileKind.CSV
    relative_dir: str
    file_name: str | None = None
    file_name_pattern: str | None = None
    orientation: Orientation | None = None
    delimiter: str = ";"
    has_header: bool = True
    matrix_value_start_index: int | None = None
    required: bool = True
    required_if: str | None = None
    depends_on: list[str] = Field(default_factory=list)
    fields: list[FieldSpecOut] = Field(default_factory=list)


def _render(spec: DataSpec) -> DataSpecOut:
    return DataSpecOut(
        **{k: getattr(spec, k) for k in (
            "id", "label", "module", "kind", "relative_dir", "file_name",
            "file_name_pattern", "orientation", "delimiter", "has_header",
            "matrix_value_start_index", "required", "required_if", "gaml_source", "origin",
        )},
        depends_on=list(spec.depends_on),
        multi_instance=spec.multi_instance,
        fields=[
            FieldSpecOut(
                name=f.name, label=f.label, type=f.type, required=f.required, unit=f.unit,
                allowed_values=list(f.allowed_values),
                references_data_spec=f.references_data_spec, position=f.position,
            )
            for f in spec.fields
        ],
    )


# ── Reads ───────────────────────────────────────────────────────────────────

@router.get("/dataspecs", response_model=list[DataSpecOut])
async def list_all(repo: Repo, module: str | None = Query(default=None)) -> list[DataSpecOut]:
    return [_render(s) for s in await use_cases.list_specs(repo, module)]


@router.get("/dataspecs/graph", tags=["input catalog"])
async def graph(repo: Repo) -> dict[str, Any]:
    """Topological levels of the dependencies between files."""
    return await use_cases.dependency_graph(repo)


@router.post("/dataspecs/applicable", response_model=list[DataSpecOut])
async def applicable(
    repo: Repo, config: Annotated[dict[str, Any], Body(default_factory=dict)]
) -> list[DataSpecOut]:
    """Files expected for a given modelling configuration."""
    return [_render(s) for s in await use_cases.list_applicable(repo, config)]


@router.get("/dataspecs/{spec_id}", response_model=DataSpecOut)
async def get_one(repo: Repo, spec_id: str) -> DataSpecOut:
    return _render(await use_cases.get_spec(repo, spec_id))


# ── Writes (administration) ─────────────────────────────────────────────────

@router.put("/admin/dataspecs/{spec_id}", response_model=DataSpecOut)
async def save(
    repo: Repo, session: Session, spec_id: str, payload: DataSpecIn
) -> DataSpecOut:
    spec = DataSpec(
        id=spec_id,
        **payload.model_dump(exclude={"depends_on", "fields"}),
        depends_on=tuple(payload.depends_on),
        # A manual write flips to USER: the seed will no longer overwrite it.
        origin="USER",
        fields=tuple(
            FieldSpec(
                name=f.name, label=f.label, type=f.type, required=f.required, unit=f.unit,
                allowed_values=tuple(f.allowed_values),
                references_data_spec=f.references_data_spec, position=f.position,
            )
            for f in payload.fields
        ),
    )
    saved = await use_cases.save_spec(repo, spec)
    await session.commit()
    return _render(saved)


@router.post("/admin/dataspecs/{spec_id}/restore", response_model=DataSpecOut)
async def restore(repo: Repo, session: Session, spec_id: str) -> DataSpecOut:
    """Revenir à ce que dit le catalogue de référence, et rendre la spec au seed."""
    spec = await use_cases.restore_spec(repo, spec_id, load_seed())
    await session.commit()
    return _render(spec)


@router.delete("/admin/dataspecs/{spec_id}", status_code=204)
async def delete(repo: Repo, session: Session, spec_id: str) -> None:
    await use_cases.delete_spec(repo, spec_id)
    await session.commit()


# ── Paramètres de scénario (administration) ─────────────────────────────────

class ParameterIn(BaseModel):
    label: str
    group: str
    type: ParameterType = ParameterType.STRING
    default: Any = None
    allowed_values: list[str] = Field(default_factory=list)
    editable: bool = True
    # Où lire les valeurs acceptables : '<identifiant de fichier>#<champ>'.
    options_from: str | None = None
    # Condition d'activité : '<autre paramètre> == true'.
    enabled_if: str | None = None


class ParameterOut(ParameterIn):
    name: str
    system: bool
    origin: str


def _render_parameter(spec: ParameterSpec) -> ParameterOut:
    return ParameterOut(
        name=spec.name, label=spec.label, group=spec.group, type=spec.type,
        default=spec.default, allowed_values=list(spec.allowed_values),
        editable=spec.editable, options_from=spec.options_from,
        enabled_if=spec.enabled_if, system=spec.system, origin=spec.origin,
    )


@router.get("/parameters/{name}", response_model=ParameterOut, tags=["input catalog"])
async def get_parameter(parameters: Parameters, name: str) -> ParameterOut:
    spec = await parameters.get(name)
    if spec is None:
        raise NotFoundError(f"paramètre inconnu : {name}")
    return _render_parameter(spec)


@router.put("/admin/parameters/{name}", response_model=ParameterOut)
async def save_parameter(
    parameters: Parameters, session: Session, name: str, payload: ParameterIn
) -> ParameterOut:
    """Écrire un paramètre. Toute écriture manuelle le bascule en USER."""
    existant = await parameters.get(name)
    spec = ParameterSpec(
        name=name,
        **payload.model_dump(exclude={"allowed_values"}),
        allowed_values=tuple(payload.allowed_values),
        # Un paramètre piloté par la plateforme le reste : ce n'est pas une
        # propriété que l'administrateur décide.
        system=existant.system if existant else False,
        origin="USER",
    )
    saved = await use_cases.save_parameter(parameters, spec)
    await session.commit()
    return _render_parameter(saved)


@router.post("/admin/parameters/{name}/restore", response_model=ParameterOut)
async def restore_parameter(parameters: Parameters, session: Session, name: str) -> ParameterOut:
    """Revenir à ce que le launcher déclare, et rendre le paramètre au seed."""
    spec = await use_cases.restore_parameter(parameters, name, load_parameter_seed())
    await session.commit()
    return _render_parameter(spec)


@router.delete("/admin/parameters/{name}", status_code=204)
async def delete_parameter(parameters: Parameters, session: Session, name: str) -> None:
    await use_cases.delete_parameter(parameters, name)
    await session.commit()
