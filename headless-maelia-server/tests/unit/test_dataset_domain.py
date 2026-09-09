"""Dataset domain: versioning, validation, shapefile sets — no infrastructure."""

import uuid

import pytest

from app.contexts.catalog.domain.models import (
    DataSpec,
    FieldSpec,
    FieldType,
    FileKind,
    Orientation,
)
from app.contexts.dataset.domain.codec import Table
from app.contexts.dataset.domain.models import (
    Dataset,
    DatasetVersion,
    VersionFile,
    VersionStatus,
)
from app.contexts.dataset.domain.services import (
    check_shapefile_set,
    content_hash,
    expected_file_names,
    normalise_upload_name,
    validate,
)


def spec(**kw) -> DataSpec:
    base = dict(id="agri.x", label="x", module="modeleAgricole", kind=FileKind.CSV,
                relative_dir="modeleAgricole", file_name="x.csv",
                orientation=Orientation.FIELDS_AS_COLUMNS)
    return DataSpec(**{**base, **kw})


def version(number: int, status: VersionStatus = VersionStatus.VALID) -> DatasetVersion:
    return DatasetVersion(
        id=uuid.uuid4(), dataset_id=uuid.uuid4(), number=number, status=status
    )


def dataset(*versions: DatasetVersion, current: uuid.UUID | None = None) -> Dataset:
    return Dataset(
        id=uuid.uuid4(), project_id=uuid.uuid4(), data_spec_id="agri.x",
        current_version_id=current, versions=versions,
    )


# ── Versioning ──────────────────────────────────────────────────────────────

def test_version_numbers_start_at_one():
    assert dataset().next_version_number == 1
    assert dataset(version(1), version(2)).next_version_number == 3


def test_version_zero_is_impossible():
    with pytest.raises(ValueError):
        DatasetVersion(id=uuid.uuid4(), dataset_id=uuid.uuid4(), number=0)


def test_default_version_is_the_latest_valid_one():
    """What a scenario gets when it pins nothing."""
    data = dataset(version(1), version(2), version(3))
    assert data.current_version.number == 3


def test_invalid_version_does_not_become_the_default():
    """Publishing a version that fails validation must not silently break every
    scenario that relies on the latest one."""
    data = dataset(version(1), version(2, VersionStatus.INVALID))
    assert data.current_version.number == 1


def test_explicit_current_version_wins():
    chosen = version(1)
    data = dataset(chosen, version(2), current=chosen.id)
    assert data.current_version.number == 1


def test_display_name_falls_back_to_the_number():
    assert version(2).display_name == "v2"
    labelled = DatasetVersion(
        id=uuid.uuid4(), dataset_id=uuid.uuid4(), number=2, label="ITK bas intrants"
    )
    assert labelled.display_name == "ITK bas intrants"


# ── Content addressing ──────────────────────────────────────────────────────

def test_identical_content_shares_one_hash():
    assert content_hash(b"abc") == content_hash(b"abc")
    assert content_hash(b"abc") != content_hash(b"abd")


# ── Validation ──────────────────────────────────────────────────────────────

def field(name: str, **kw) -> FieldSpec:
    return FieldSpec(name=name, **kw)


def test_empty_file_is_reported():
    assert validate(Table((), ()), spec())[0].message == "le fichier est vide"


def test_missing_required_column():
    schema = spec(fields=(field("ID", required=True), field("NOM")))
    issues = validate(Table(("NOM",), (("ble",),)), schema)
    assert any("colonne obligatoire absente : ID" in i.message for i in issues)


def test_column_case_does_not_raise_a_false_alarm():
    """Exporters vary on capitalisation; a spurious error would block a good file."""
    schema = spec(fields=(field("ID_EXPL", required=True),))
    assert validate(Table(("id_expl",), (("a",),)), schema) == []


def test_type_error_is_located():
    schema = spec(fields=(field("RENDEMENT", type=FieldType.FLOAT),))
    issues = validate(Table(("RENDEMENT",), (("9.5",), ("beaucoup",))), schema)
    assert len(issues) == 1
    assert issues[0].row_index == 2
    assert issues[0].field_name == "RENDEMENT"


def test_na_does_not_fail_validation():
    """MAELIA writes a literal NA for a missing value."""
    schema = spec(fields=(field("RENDEMENT", type=FieldType.FLOAT),))
    assert validate(Table(("RENDEMENT",), (("NA",),)), schema) == []


def test_validation_reads_positionally():
    """A transposed file repeats field names: only the position identifies them."""
    schema = spec(
        orientation=Orientation.FIELDS_AS_ROWS,
        fields=(field("OP", type=FieldType.STRING), field("OP", type=FieldType.INT)),
    )
    issues = validate(Table(("OP", "OP"), (("labour", "12"),)), schema)
    assert issues == []
    # The second column is typed INT: a text value must be caught there.
    bad = validate(Table(("OP", "OP"), (("labour", "hersage"),)), schema)
    assert len(bad) == 1


# ── Shapefiles ──────────────────────────────────────────────────────────────

def shapefile() -> DataSpec:
    return spec(kind=FileKind.SHAPEFILE, file_name="ilots.shp", orientation=None)


def test_a_shapefile_version_expects_four_files():
    assert expected_file_names(shapefile()) == [
        "ilots.shp", "ilots.shx", "ilots.dbf", "ilots.prj"
    ]


def test_incomplete_shapefile_is_refused():
    issues = check_shapefile_set(shapefile(), ["ilots.shp"])
    assert issues and "shapefile incomplet" in issues[0].message


def test_shapefile_without_prj_is_accepted():
    """`.prj` is optional: many shipped shapefiles do not carry one."""
    assert check_shapefile_set(shapefile(), ["ilots.shp", "ilots.shx", "ilots.dbf"]) == []


def test_a_csv_spec_is_not_checked_as_a_shapefile():
    assert check_shapefile_set(spec(), ["x.csv"]) == []


# ── Upload naming ───────────────────────────────────────────────────────────

def test_upload_is_renamed_to_what_the_model_expects():
    """The user uploads ilots_v2.shp; GAMA reads ilots.shp."""
    assert normalise_upload_name(shapefile(), "ilots_v2.shp", None) == "ilots.shp"
    assert normalise_upload_name(shapefile(), "ilots_v2.dbf", None) == "ilots.dbf"
    assert normalise_upload_name(spec(), "mon_export.csv", None) == "x.csv"


def test_multi_instance_keeps_its_instance_name():
    weather = spec(id="commun.meteo", file_name=None, file_name_pattern=r"\d{4}\.csv")
    assert normalise_upload_name(weather, "2018.csv", "2018.csv") == "2018.csv"


def test_version_file_lookup():
    files = (VersionFile("ilots.shp", "h1", 10), VersionFile("ilots.dbf", "h2", 20))
    v = DatasetVersion(id=uuid.uuid4(), dataset_id=uuid.uuid4(), number=1, files=files)
    assert v.file("ilots.dbf").content_hash == "h2"
    assert v.file("absent.shp") is None
