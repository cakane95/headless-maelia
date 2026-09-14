"""The output adapter: what it exposes, and what it refuses.

Uses a temporary directory as the run's announced output directory, so no
container and no simulation are needed.
"""

import pytest

from app.contexts.result.domain.models import OutputKind
from app.contexts.result.infrastructure.file_store import FileOutputStore
from app.shared.errors import NotFoundError


@pytest.fixture
def run(tmp_path):
    (tmp_path / "sorties_eau.csv").write_text("annee;pluie[mm]\n2019;215.9\n", encoding="utf-8")
    (tmp_path / "simulationParameters.txt").write_text(
        "version GAMA\t2025.6.4\nversion MAELIA\t1.4.29\n", encoding="utf-8"
    )
    (tmp_path / "carte.png").write_bytes(b"\x89PNG\r\n")
    return {"id": "run-de-test", "output_dir": str(tmp_path)}


async def test_lists_files_with_what_can_be_done_with_them(run):
    files = {f.name: f.kind for f in await FileOutputStore().list_files(run)}
    assert files["sorties_eau.csv"] is OutputKind.TABLE
    assert files["carte.png"] is OutputKind.BINARY


async def test_a_two_column_text_file_is_not_a_table(run):
    """simulationParameters.txt is a key/value list: charting it means nothing."""
    files = {f.name: f.kind for f in await FileOutputStore().list_files(run)}
    assert files["simulationParameters.txt"] is OutputKind.TEXT


async def test_reads_a_file_of_the_run(run):
    assert b"215.9" in await FileOutputStore().read(run, "sorties_eau.csv")


async def test_a_run_without_outputs_lists_nothing_rather_than_failing():
    assert await FileOutputStore().list_files({"id": "jamais-lance"}) == []


@pytest.mark.parametrize(
    "name", ["../../../etc/passwd", "..\\..\\secret", "inconnu.csv", "sous/dossier.csv"]
)
async def test_refuses_anything_outside_the_run_directory(run, name):
    with pytest.raises(NotFoundError):
        await FileOutputStore().read(run, name)
