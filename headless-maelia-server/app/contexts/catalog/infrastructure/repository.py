"""SQLAlchemy adapter for the catalog.

Satisfies `CatalogRepository` without inheriting from it: `Protocol` is structural.
The mapping lives here, in two explicit functions — no mapper layer.
"""

from sqlalchemy import delete as sql_delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.contexts.catalog.domain.models import (
    DataSpec,
    FieldSpec,
    FieldType,
    FileKind,
    Orientation,
    ParameterSpec,
    ParameterType,
)
from app.contexts.catalog.infrastructure.persistence import (
    DataSpecRow,
    FieldSpecRow,
    ParameterSpecRow,
)

SEPARATOR = "|"


def _to_domain(row: DataSpecRow) -> DataSpec:
    return DataSpec(
        id=row.id,
        label=row.label,
        module=row.module,
        kind=FileKind(row.kind),
        relative_dir=row.relative_dir,
        file_name=row.file_name,
        file_name_pattern=row.file_name_pattern,
        orientation=Orientation(row.orientation) if row.orientation else None,
        delimiter=row.delimiter,
        has_header=row.has_header,
        matrix_value_start_index=row.matrix_value_start_index,
        required=row.required,
        required_if=row.required_if,
        depends_on=tuple(row.depends_on.split(SEPARATOR)) if row.depends_on else (),
        gaml_source=row.gaml_source,
        origin=row.origin,
        fields=tuple(
            FieldSpec(
                name=f.name,
                label=f.label,
                type=FieldType(f.type),
                required=f.required,
                unit=f.unit,
                allowed_values=tuple(f.allowed_values.split(SEPARATOR))
                if f.allowed_values
                else (),
                references_data_spec=f.references_data_spec,
                position=f.position,
            )
            for f in row.fields
        ),
    )


def _apply(row: DataSpecRow, spec: DataSpec) -> DataSpecRow:
    row.id = spec.id
    row.label = spec.label
    row.module = spec.module
    row.kind = spec.kind.value
    row.relative_dir = spec.relative_dir
    row.file_name = spec.file_name
    row.file_name_pattern = spec.file_name_pattern
    row.orientation = spec.orientation.value if spec.orientation else None
    row.delimiter = spec.delimiter
    row.has_header = spec.has_header
    row.matrix_value_start_index = spec.matrix_value_start_index
    row.required = spec.required
    row.required_if = spec.required_if
    row.depends_on = SEPARATOR.join(spec.depends_on) or None
    row.gaml_source = spec.gaml_source
    row.origin = spec.origin
    return row


class SqlCatalogRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def list_all(self) -> list[DataSpec]:
        result = await self._session.execute(
            select(DataSpecRow).options(selectinload(DataSpecRow.fields)).order_by(DataSpecRow.id)
        )
        return [_to_domain(r) for r in result.scalars()]

    async def get(self, spec_id: str) -> DataSpec | None:
        result = await self._session.execute(
            select(DataSpecRow)
            .options(selectinload(DataSpecRow.fields))
            .where(DataSpecRow.id == spec_id)
        )
        row = result.scalar_one_or_none()
        return _to_domain(row) if row else None

    async def upsert(self, spec: DataSpec) -> DataSpec:
        result = await self._session.execute(
            select(DataSpecRow)
            .options(selectinload(DataSpecRow.fields))
            .where(DataSpecRow.id == spec.id)
        )
        row = result.scalar_one_or_none()
        if row is None:
            row = DataSpecRow()
            self._session.add(row)
        _apply(row, spec)

        # Fields are replaced wholesale: their order carries meaning (column
        # position), and a row-by-row diff would add complexity for nothing.
        await self._session.execute(
            sql_delete(FieldSpecRow).where(FieldSpecRow.data_spec_id == spec.id)
        )
        for position, spec_field in enumerate(spec.fields):
            self._session.add(
                FieldSpecRow(
                    data_spec_id=spec.id,
                    name=spec_field.name,
                    label=spec_field.label,
                    type=spec_field.type.value,
                    required=spec_field.required,
                    unit=spec_field.unit,
                    allowed_values=SEPARATOR.join(spec_field.allowed_values) or None,
                    references_data_spec=spec_field.references_data_spec,
                    position=spec_field.position or position,
                )
            )
        await self._session.flush()
        return spec

    async def delete(self, spec_id: str) -> bool:
        result = await self._session.execute(
            sql_delete(DataSpecRow).where(DataSpecRow.id == spec_id)
        )
        return result.rowcount > 0

    async def count(self) -> int:
        result = await self._session.execute(select(func.count()).select_from(DataSpecRow))
        return int(result.scalar_one())


def _parameter_to_domain(row: ParameterSpecRow) -> ParameterSpec:
    return ParameterSpec(
        name=row.name,
        label=row.label,
        group=row.group,
        type=ParameterType(row.type),
        default=row.default,
        allowed_values=tuple(row.allowed_values.split(SEPARATOR)) if row.allowed_values else (),
        system=row.system,
        editable=row.editable,
        origin=row.origin,
    )


class SqlParameterRepository:
    """Scenario-parameter catalog."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def list_all(self) -> list[ParameterSpec]:
        result = await self._session.execute(
            select(ParameterSpecRow).order_by(ParameterSpecRow.group, ParameterSpecRow.name)
        )
        return [_parameter_to_domain(r) for r in result.scalars()]

    async def get(self, name: str) -> ParameterSpec | None:
        row = await self._session.get(ParameterSpecRow, name)
        return _parameter_to_domain(row) if row else None

    async def upsert(self, spec: ParameterSpec) -> ParameterSpec:
        row = await self._session.get(ParameterSpecRow, spec.name)
        if row is None:
            row = ParameterSpecRow(name=spec.name)
            self._session.add(row)
        row.label = spec.label
        row.group = spec.group
        row.type = spec.type.value
        row.default = spec.default
        row.allowed_values = SEPARATOR.join(spec.allowed_values) or None
        row.system = spec.system
        row.editable = spec.editable
        row.origin = spec.origin
        await self._session.flush()
        return spec
