"""Where a parameter's acceptable values come from — no database, no MinIO.

The point of these tests is that the platform reads the **project's own** data:
a farm identifier offered for a project must exist in that project's file.
"""

import io
import uuid

import pytest
import shapefile

from app.contexts.catalog.domain.models import DataSpec, FileKind, ParameterSpec, ParameterType
from app.contexts.dataset.domain.models import Dataset, DatasetVersion, VersionFile, VersionStatus
from app.contexts.scenario.application.options import parameter_options

PROJECT = uuid.uuid4()

EXPLOITATIONS = DataSpec(
    id="agri.agriculteurs.exploitations",
    label="exploitations.csv",
    module="modeleAgricole",
    kind=FileKind.CSV,
    relative_dir="modeleAgricole/agriculteurs",
    file_name="exploitations.csv",
)
PARCELLES = DataSpec(
    id="agri.ilots.dansZone.parcelles",
    label="parcelles.shp",
    module="modeleAgricole",
    kind=FileKind.SHAPEFILE,
    relative_dir="modeleAgricole/ilots/dansZone",
    file_name="parcelles.shp",
)
PRIX = DataSpec(
    id="agri.marcheAgricole.prixVentes",
    label="Prix de vente par scénario",
    module="modeleAgricole",
    kind=FileKind.CSV,
    relative_dir="modeleAgricole/marcheAgricole",
    file_name_pattern=r"prixVentes.+\.csv",
)

CSV_BYTES = b"ID_EXPL;TYPE_EXPL\nmineral_beauce_29;mineral\norganique_beauce_25;organique\nmineral_beauce_29;mineral\n"


def dbf_bytes(rows: list[tuple[str, str]]) -> bytes:
    """A `.dbf` on its own — which is exactly what the reader is given."""
    dbf = io.BytesIO()
    writer = shapefile.Writer(dbf=dbf, shp=io.BytesIO(), shx=io.BytesIO())
    writer.field("ID_PARCELL", "C", 40)
    writer.field("CULT_REF", "C", 40)
    for identifier, culture in rows:
        writer.record(identifier, culture)
        writer.null()
    writer.close()
    return dbf.getvalue()


def spec(name: str, options_from: str | None, kind=ParameterType.STRING) -> ParameterSpec:
    return ParameterSpec(
        name=name, label=name, group="Général", type=kind, options_from=options_from
    )


def dataset(data_spec_id: str, files: tuple[VersionFile, ...], instance_key=None) -> Dataset:
    version = DatasetVersion(
        id=uuid.uuid4(),
        dataset_id=uuid.uuid4(),
        number=1,
        status=VersionStatus.VALID,
        files=files,
    )
    return Dataset(
        id=uuid.uuid4(),
        project_id=PROJECT,
        data_spec_id=data_spec_id,
        instance_key=instance_key,
        current_version_id=version.id,
        versions=(version,),
    )


class FakeCatalog:
    def __init__(self, *specs: DataSpec) -> None:
        self._specs = {s.id: s for s in specs}

    async def get(self, data_spec_id: str) -> DataSpec | None:
        return self._specs.get(data_spec_id)


class FakeDatasets:
    def __init__(self, *datasets: Dataset) -> None:
        self._datasets = list(datasets)

    async def list_for_project(self, project_id: uuid.UUID) -> list[Dataset]:
        return self._datasets


class FakeBlobs:
    def __init__(self, **payloads: bytes) -> None:
        self._payloads = payloads

    async def get(self, content_hash: str) -> bytes:
        return self._payloads[content_hash]


async def resolve(parameter, catalog, datasets, blobs):
    return await parameter_options(parameter, catalog, datasets, blobs, PROJECT)


class TestSourceDeclaration:
    def test_a_source_splits_into_file_and_column(self):
        parameter = spec("idExploitationAexecuter", "agri.agriculteurs.exploitations#ID_EXPL")
        assert parameter.options_source == ("agri.agriculteurs.exploitations", "ID_EXPL")

    def test_an_empty_column_means_the_instances_themselves(self):
        assert spec("listScenarioPrix", "agri.marcheAgricole.prixVentes#").options_source == (
            "agri.marcheAgricole.prixVentes",
            None,
        )

    def test_no_source_at_all(self):
        assert spec("verboseMode", None).options_source is None


class TestReadingValues:
    async def test_reads_a_csv_column_without_duplicates(self):
        found = await resolve(
            spec("idExploitationAexecuter", "agri.agriculteurs.exploitations#ID_EXPL"),
            FakeCatalog(EXPLOITATIONS),
            FakeDatasets(dataset(EXPLOITATIONS.id, (VersionFile("exploitations.csv", "h1", 4),))),
            FakeBlobs(h1=CSV_BYTES),
        )
        assert found.available
        assert found.values == ("mineral_beauce_29", "organique_beauce_25")

    async def test_reads_a_shapefile_through_its_dbf_alone(self):
        """The geometry is never needed to list identifiers."""
        payload = dbf_bytes([("sudouest_1_1", "maisT"), ("beauce_1_1", "colza")])
        found = await resolve(
            spec("nomParcelleAffichee", "agri.ilots.dansZone.parcelles#ID_PARCELL"),
            FakeCatalog(PARCELLES),
            FakeDatasets(
                dataset(
                    PARCELLES.id,
                    (VersionFile("parcelles.shp", "shp", 9), VersionFile("parcelles.dbf", "dbf", 4)),
                )
            ),
            FakeBlobs(dbf=payload),
        )
        assert found.values == ("beauce_1_1", "sudouest_1_1")

    async def test_a_multi_instance_file_offers_its_instances(self):
        found = await resolve(
            spec("listScenarioPrix", "agri.marcheAgricole.prixVentes#"),
            FakeCatalog(PRIX),
            FakeDatasets(
                dataset(PRIX.id, (), instance_key="prixVentesSC1.csv"),
                dataset(PRIX.id, (), instance_key="prixVentesSC2.csv"),
            ),
            FakeBlobs(),
        )
        assert found.values == ("prixVentesSC1", "prixVentesSC2")


class TestWhenNothingCanBeOffered:
    """Each refusal names a different gesture: load a file, fix a column, type freely."""

    async def test_a_parameter_without_source_stays_free(self):
        found = await resolve(spec("verboseMode", None), FakeCatalog(), FakeDatasets(), FakeBlobs())
        assert not found.available and "libre" in found.message

    async def test_a_file_not_loaded_in_the_project(self):
        found = await resolve(
            spec("idExploitationAexecuter", "agri.agriculteurs.exploitations#ID_EXPL"),
            FakeCatalog(EXPLOITATIONS),
            FakeDatasets(),
            FakeBlobs(),
        )
        assert not found.available and "pas encore chargé" in found.message

    async def test_a_column_the_loaded_file_does_not_have(self):
        found = await resolve(
            spec("idSdcForce", "agri.ilots.dansZone.parcelles#ID_SDC"),
            FakeCatalog(PARCELLES),
            FakeDatasets(
                dataset(PARCELLES.id, (VersionFile("parcelles.dbf", "dbf", 4),))
            ),
            FakeBlobs(dbf=dbf_bytes([("p1", "maisT")])),
        )
        assert not found.available and "ID_SDC" in found.message

    async def test_an_unknown_file_is_a_catalog_error(self):
        from app.shared.errors import NotFoundError

        with pytest.raises(NotFoundError):
            await resolve(
                spec("x", "fichier.inexistant#CHAMP"), FakeCatalog(), FakeDatasets(), FakeBlobs()
            )
