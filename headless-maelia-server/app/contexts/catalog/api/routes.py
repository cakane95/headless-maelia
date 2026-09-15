"""Input catalog routes — ADMINISTRATION domain.

Reads are open (the simulation domain needs them); writes sit under the `/admin`
prefix.
"""

from typing import Annotated, Any

from fastapi import APIRouter, Body, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.contexts.catalog.application import outputs as output_cases, use_cases
from app.contexts.catalog.domain.models import (
    DataSpec,
    FieldSpec,
    FieldType,
    FileKind,
    Granularity,
    Orientation,
    OutputFileSpec,
    OutputSpec,
    ParameterSpec,
    ParameterType,
)
from app.contexts.catalog.domain.outputs import Production
from app.contexts.catalog.infrastructure.repository import (
    SqlCatalogRepository,
    SqlOutputRepository,
    SqlParameterRepository,
)
from app.contexts.catalog.infrastructure.seed import (
    load_output_seed,
    load_parameter_seed,
    load_seed,
)
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


# ── Sorties du modèle (administration) ──────────────────────────────────────


def output_repository(
    session: Annotated[AsyncSession, Depends(get_session)],
) -> SqlOutputRepository:
    return SqlOutputRepository(session)


Outputs = Annotated[SqlOutputRepository, Depends(output_repository)]


class OutputFileOut(BaseModel):
    name: str
    granularity: Granularity = Granularity.UNKNOWN


class OutputIn(BaseModel):
    label: str
    theme: str
    description: str | None = None
    flag: str | None = None
    files: list[OutputFileOut] = Field(default_factory=list)
    # Condition de production, dans le langage du catalogue.
    produced_if: str | None = None


class OutputOut(OutputIn):
    id: str
    module: str
    # La garde GAML telle quelle : une traduction qui abandonne un terme doit
    # rester vérifiable.
    guard_source: str | None = None
    exact: bool = True
    gaml_source: str | None = None
    origin: str
    # Paramètres de la condition que le launcher n'expose pas : aucun scénario
    # ne peut agir dessus.
    unreachable: list[str] = Field(default_factory=list)


def _render_output(spec: OutputSpec, exposed: set[str]) -> OutputOut:
    return OutputOut(
        id=spec.id,
        label=spec.label,
        theme=spec.theme,
        module=spec.module,
        description=spec.description,
        flag=spec.flag,
        files=[OutputFileOut(name=f.name, granularity=f.granularity) for f in spec.files],
        produced_if=spec.produced_if,
        guard_source=spec.guard_source,
        exact=spec.exact,
        gaml_source=spec.gaml_source,
        origin=spec.origin,
        unreachable=output_cases.unreachable_terms(spec, exposed),
    )


async def _exposed(parameters: SqlParameterRepository) -> set[str]:
    return {spec.name for spec in await parameters.list_all()}


@router.get("/outputs", response_model=list[OutputOut], tags=["output catalog"])
async def list_outputs(
    outputs: Outputs,
    parameters: Parameters,
    module: str | None = Query(None),
    theme: str | None = Query(None),
) -> list[OutputOut]:
    """Ce que le modèle peut écrire, et sous quelles conditions."""
    exposed = await _exposed(parameters)
    specs = await output_cases.list_outputs(outputs, module=module, theme=theme)
    return [_render_output(spec, exposed) for spec in specs]


@router.get("/outputs/{spec_id}", response_model=OutputOut, tags=["output catalog"])
async def get_output(outputs: Outputs, parameters: Parameters, spec_id: str) -> OutputOut:
    spec = await output_cases.get_output(outputs, spec_id)
    return _render_output(spec, await _exposed(parameters))


class ExpectationOut(BaseModel):
    id: str
    label: str
    theme: str
    production: Production
    files: list[str] = Field(default_factory=list)
    # Paramètres à activer pour obtenir le fichier, le chemin le plus court.
    blocking: list[str] = Field(default_factory=list)
    reason: str = ""


@router.post("/outputs/expected", response_model=list[ExpectationOut], tags=["output catalog"])
async def expected_outputs(
    outputs: Outputs,
    parameters: Parameters,
    values: Annotated[dict[str, Any], Body(embed=True)] = {},
) -> list[ExpectationOut]:
    """Ce qu'un scénario portant ces écarts produirait.

    Le front demande, il n'évalue pas : deux évaluateurs, c'est deux réponses le
    jour où la condition change de forme.
    """
    paires = await output_cases.expectations(outputs, await parameters.list_all(), values)
    return [
        ExpectationOut(
            id=spec.id,
            label=spec.label,
            theme=spec.theme,
            production=attente.production,
            files=list(spec.file_names),
            blocking=list(attente.blocking),
            reason=attente.reason,
        )
        for spec, attente in paires
    ]


@router.put("/admin/outputs/{spec_id}", response_model=OutputOut, tags=["output catalog"])
async def save_output(
    outputs: Outputs, parameters: Parameters, session: Session, spec_id: str, payload: OutputIn
) -> OutputOut:
    """Écrire une sortie. Toute écriture manuelle la bascule en USER."""
    existant = await outputs.get(spec_id)
    spec = OutputSpec(
        id=spec_id,
        label=payload.label,
        theme=payload.theme,
        description=payload.description,
        flag=payload.flag,
        files=tuple(
            OutputFileSpec(name=f.name, granularity=f.granularity) for f in payload.files
        ),
        produced_if=payload.produced_if,
        # La garde GAML n'est pas modifiable : c'est le texte du modèle, la
        # trace qui permet de vérifier la traduction.
        guard_source=existant.guard_source if existant else None,
        exact=existant.exact if existant else True,
        gaml_source=existant.gaml_source if existant else None,
        origin="USER",
    )
    saved = await output_cases.save_output(outputs, spec)
    await session.commit()
    return _render_output(saved, await _exposed(parameters))


@router.post(
    "/admin/outputs/{spec_id}/restore", response_model=OutputOut, tags=["output catalog"]
)
async def restore_output(
    outputs: Outputs, parameters: Parameters, session: Session, spec_id: str
) -> OutputOut:
    """Revenir à ce que le modèle écrit, et rendre la sortie au seed."""
    spec = await output_cases.restore_output(outputs, spec_id, load_output_seed())
    await session.commit()
    return _render_output(spec, await _exposed(parameters))


@router.delete("/admin/outputs/{spec_id}", status_code=204, tags=["output catalog"])
async def delete_output(outputs: Outputs, session: Session, spec_id: str) -> None:
    await output_cases.delete_output(outputs, spec_id)
    await session.commit()
