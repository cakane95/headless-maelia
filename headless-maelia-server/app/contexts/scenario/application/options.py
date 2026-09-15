"""Acceptable values of a parameter, read from the project's own data.

`idExploitationAexecuter` expects a farm identifier — one that exists in *this*
project's `exploitations.csv`, not in the model's sample data. Asking the user to
type it from memory is how a run fails twenty minutes later on a typo.

The link parameter → source is catalog data (`ParameterSpec.options_from`), never
code: this module reads whatever the catalog points at.
"""

import asyncio
import io
import uuid
from dataclasses import dataclass

from app.contexts.catalog.domain.models import DataSpec, FileKind, ParameterSpec
from app.contexts.dataset.domain import codec
from app.contexts.dataset.domain.models import Dataset
from app.contexts.dataset.domain.ports import BlobStore, DatasetRepository
from app.shared.errors import NotFoundError

# A picker stops being a picker past this; the front end says so rather than
# pretending the list is complete.
MAX_VALUES = 2000


@dataclass(frozen=True, slots=True)
class Options:
    """What a parameter may be set to, and where that comes from."""

    parameter: str
    values: tuple[str, ...]
    data_spec_id: str | None = None
    field: str | None = None
    # No dataset yet in the project: the field stays free rather than empty.
    available: bool = True
    message: str | None = None
    truncated: bool = False


class CatalogReader:
    """Structural type of what this module needs from the file catalog."""

    async def get(self, data_spec_id: str) -> DataSpec | None: ...


async def parameter_options(
    spec: ParameterSpec,
    catalog: CatalogReader,
    datasets: DatasetRepository,
    blobs: BlobStore,
    project_id: uuid.UUID,
) -> Options:
    """Values this project allows for that parameter."""
    source = spec.options_source
    if source is None:
        return Options(spec.name, (), available=False, message="ce paramètre est libre")

    data_spec_id, field = source
    data_spec = await catalog.get(data_spec_id)
    if data_spec is None:
        raise NotFoundError(f"fichier inconnu du catalogue : {data_spec_id}")

    owned = [d for d in await datasets.list_for_project(project_id) if d.data_spec_id == data_spec_id]

    # Multi-instance file: the instances *are* the choices (one price-scenario
    # file per scenario), so there is no column to read.
    if field is None:
        names = sorted(_instance_label(d) for d in owned if d.instance_key)
        return _render(spec, data_spec_id, None, names, f"aucun fichier {data_spec.label} chargé")

    values = await _column_values(owned, data_spec, field, blobs)
    # Trois situations distinctes, trois messages : « pas de fichier » et
    # « colonne absente » appellent des gestes différents de l'utilisateur.
    if values is None:
        reason = f"{data_spec.label} n'est pas encore chargé dans ce projet"
    else:
        reason = f"la colonne {field} est absente ou vide dans {data_spec.label}"
    return _render(spec, data_spec_id, field, values or [], reason)


def _instance_label(dataset: Dataset) -> str:
    """Scenario name of an instance: the file name without its extension."""
    return dataset.instance_key.rsplit(".", 1)[0]


def _render(
    spec: ParameterSpec, data_spec_id: str, field: str | None, values: list[str], empty: str
) -> Options:
    if not values:
        return Options(
            spec.name, (), data_spec_id, field, available=False, message=empty,
        )
    return Options(
        spec.name,
        tuple(values[:MAX_VALUES]),
        data_spec_id,
        field,
        truncated=len(values) > MAX_VALUES,
    )


async def _column_values(
    owned: list[Dataset], data_spec: DataSpec, field: str, blobs: BlobStore
) -> list[str] | None:
    """Distinct values of a column, or `None` if the project has no such file.

    The *current* version, not an arbitrary one: it is what a run without a pin
    would consume, so the choices offered are the choices that will apply.
    """
    version = next((d.current_version for d in owned if d.current_version), None)
    if version is None:
        return None

    reader = _read_dbf if data_spec.kind is FileKind.SHAPEFILE else _read_csv
    file = _source_file(version.files, data_spec.kind)
    if file is None:
        return None

    payload = await blobs.get(file.content_hash)
    values = await asyncio.to_thread(reader, payload, data_spec, field)
    return sorted({v for v in values if v})


def _source_file(files, kind: FileKind):
    """The file carrying the attributes: the `.dbf` of a shapefile, else the file."""
    if kind is FileKind.SHAPEFILE:
        return next((f for f in files if f.file_name.lower().endswith(".dbf")), None)
    return files[0] if files else None


def _read_csv(payload: bytes, data_spec: DataSpec, field: str) -> list[str]:
    """Column of a tabular file, read through the codec that knows its shape."""
    table = codec.decode(payload, data_spec)
    return [str(record.get(field, "")).strip() for record in table.as_records()]


def _read_dbf(payload: bytes, _: DataSpec, field: str) -> list[str]:
    """Attribute of a shapefile, read from its `.dbf` alone.

    A `.dbf` is a table in its own right: the geometry is not needed to list the
    identifiers, so the `.shp` never has to be downloaded.
    """
    import shapefile  # imported here: only this path needs it

    with shapefile.Reader(dbf=io.BytesIO(payload)) as reader:
        names = [f[0] for f in reader.fields[1:]]
        if field not in names:
            return []
        position = names.index(field)
        return [str(record[position]).strip() for record in reader.iterRecords()]
