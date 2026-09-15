"""CSV codec: the symmetry that protects the "bytes are never regenerated" rule.

Runs against the REAL files shipped under `includes/` when they are reachable —
a synthetic fixture would not exercise the BOM, the latin-1 fallback or the meta
column of `reglesDeDecisions.csv`.

Which territory supplies them does not matter, and is not fixed here: those
folders exist to exercise GAMA, they come and go. The test takes the first
territory that has the file, and skips when none does.
"""

import pathlib

import pytest

from app.contexts.catalog.domain.models import DataSpec, FileKind, Orientation
from app.contexts.dataset.domain.codec import Table, decode, encode

INCLUDES = pathlib.Path(
    "/usr/lib/gama/workspace/gama-models/MAELIA_1.4.29_GAMA_2025-06/includes"
)


def shipped(relative: str) -> pathlib.Path | None:
    """The file under whichever shipped territory happens to carry it."""
    if not INCLUDES.is_dir():
        return None
    for territory in sorted(p for p in INCLUDES.iterdir() if p.is_dir()):
        candidate = territory / relative
        if candidate.is_file():
            return candidate
    return None


def spec(**kw) -> DataSpec:
    base = dict(id="x", label="x", module="m", kind=FileKind.CSV, relative_dir="m",
                file_name="x.csv", orientation=Orientation.FIELDS_AS_COLUMNS)
    return DataSpec(**{**base, **kw})


def transposed(**kw) -> DataSpec:
    """Field names in column 0, one entity per following column."""
    return spec(orientation=Orientation.FIELDS_AS_ROWS, **kw)


# ── Column-oriented ─────────────────────────────────────────────────────────

def test_decode_columns():
    raw = b"ID_EXPL;TYPE_EXPL\nexpl_1;mineral\nexpl_2;organique\n"
    table = decode(raw, spec())
    assert table.columns == ("ID_EXPL", "TYPE_EXPL")
    assert table.rows == (("expl_1", "mineral"), ("expl_2", "organique"))


def test_roundtrip_columns():
    original = Table(
        columns=("ID_EXPL", "TYPE_EXPL"),
        rows=(("expl_1", "mineral"), ("expl_2", "organique")),
    )
    assert decode(encode(original, spec()), spec()) == original


def test_short_line_keeps_its_width():
    """A short line is NOT padded.

    Padding would add trailing delimiters the file never had, and publication
    would then rewrite it. Missing cells are surfaced by `as_records`, which is
    where validation looks.
    """
    raw = b"a;b;c\n1;2\n"
    table = decode(raw, spec())
    assert table.rows == (("1", "2"),)
    assert encode(table, spec()) == raw


def test_decode_transposed():
    """Field names in column 0, one entity per following column."""
    raw = b"ESPECE;maisP;ble\nRENDEMENT;9.5;7.2\nCOULEUR;rouge;vert\n"
    table = decode(raw, transposed())
    assert table.columns == ("ESPECE", "RENDEMENT", "COULEUR")
    assert table.rows == (("maisP", "9.5", "rouge"), ("ble", "7.2", "vert"))


def test_decode_transposed_with_meta_column():
    """reglesDeDecisions.csv inserts a meta column before the values."""
    raw = b"NOM_ITK;X.;itk_a;itk_b\nID_ITK;[NA];a;b\n"
    table = decode(raw, transposed(matrix_value_start_index=2))
    assert table.columns == ("NOM_ITK", "ID_ITK")
    # The meta column is not data: values start at index 2.
    assert table.rows == (("itk_a", "a"), ("itk_b", "b"))


def test_roundtrip_transposed():
    original = Table(
        columns=("ESPECE", "RENDEMENT"),
        rows=(("maisP", "9.5"), ("ble", "7.2")),
    )
    assert decode(encode(original, transposed()), transposed()) == original


def test_repeated_field_names_survive():
    """reglesDeDecisions.csv repeats row labels (several operations per ITK).

    A name-keyed model would lose values here; positions do not.
    """
    original = Table(
        columns=("TRAVAIL_SOL", "TRAVAIL_SOL", "SEMIS"),
        rows=(("labour", "hersage", "15/03"),),
    )
    decoded = decode(encode(original, transposed()), transposed())
    assert decoded == original
    assert decoded.rows[0] == ("labour", "hersage", "15/03")
    # The name-keyed view disambiguates rather than dropping.
    assert decoded.as_records()[0] == {
        "TRAVAIL_SOL": "labour", "TRAVAIL_SOL__2": "hersage", "SEMIS": "15/03",
    }


# ── Encodings ───────────────────────────────────────────────────────────────

def test_bom_is_stripped():
    raw = "﻿NOM;VALEUR\na;1\n".encode()
    assert decode(raw, spec()).columns == ("NOM", "VALEUR")


def test_latin1_fallback():
    """Some shipped files are ISO-8859-1; decoding must not fail."""
    raw = "NOM;LIBELLE\nble;blé tendre\n".encode("latin-1")
    assert decode(raw, spec()).rows == (("ble", "blé tendre"),)


# ── Real files ──────────────────────────────────────────────────────────────

REAL_FILES = [
    ("modeleAgricole/agriculteurs/exploitations.csv", None, None),
    ("modeleCommun/date/joursParMois.csv", None, None),
    ("modeleAgricole/culture/especesCultivees.csv", Orientation.FIELDS_AS_ROWS, 1),
    ("modeleAgricole/culture/reglesDeDecisions.csv", Orientation.FIELDS_AS_ROWS, 2),
]


@pytest.mark.parametrize(("relative", "orientation", "start"), REAL_FILES)
def test_roundtrip_on_shipped_files(relative, orientation, start):
    """The codec must be stable on the real data.

    Byte equality is checked in `tests/integration/test_codec_roundtrip.py`,
    across every shipped file. Here we guard the weaker but faster property:
    a published version, once serialised, decodes back to the same table.
    """
    path = shipped(relative)
    if path is None:
        pytest.skip(f"shipped file unavailable: {relative}")

    file_spec = spec(
        orientation=orientation or Orientation.FIELDS_AS_COLUMNS,
        matrix_value_start_index=start,
    )
    once = decode(path.read_bytes(), file_spec)
    assert once.columns, f"{relative}: no field read"

    twice = decode(encode(once, file_spec), file_spec)
    assert twice == once, f"{relative}: codec is not symmetric"


# ── Draft round trip ────────────────────────────────────────────────────────

def test_from_records_is_the_inverse_of_as_records():
    """Publication rebuilds rows from name-keyed records: the two must be inverse."""
    original = Table(
        columns=("TRAVAIL_SOL", "TRAVAIL_SOL", "SEMIS"),
        rows=(("labour", "hersage", "15/03"), ("labour2", "hersage2", "20/03")),
    )
    rebuilt = Table.from_records(original.as_records(), original.columns, original.dialect)
    assert rebuilt == original


def test_column_order_comes_from_the_template_not_the_records():
    """The draft is stored as JSONB: the database may normalise its key order.

    Rebuilding columns from record keys would silently reorder the file — which
    is exactly what happened before this guard.
    """
    columns = ("ZZZ", "AAA", "MMM")
    records = [{"AAA": "1", "MMM": "2", "ZZZ": "3"}]  # keys sorted, as JSONB returns them
    table = Table.from_records(records, columns)
    assert table.columns == columns
    assert table.rows == (("3", "1", "2"),)
