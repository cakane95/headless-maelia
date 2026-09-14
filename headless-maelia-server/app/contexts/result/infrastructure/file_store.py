"""Output files read from the model tree.

`idSimulationAPI` makes a run write into `models/main/log/<runId>`, so the
directory is deterministic and isolated per run. The run record also carries the
path GAMA announced on its console, which covers a change of convention.

Reading is blocking: every method hands the file system to a thread, as required
of any adapter called from the event loop.
"""

import asyncio
from pathlib import Path

from app.contexts.result.domain.models import OutputFile, OutputKind
from app.shared.config import settings
from app.shared.errors import NotFoundError

# Extensions whose content the platform can read. Anything else is downloadable
# but not displayed — guessing at bytes helps nobody.
TABLE_SUFFIXES = {".csv", ".tsv"}
TEXT_SUFFIXES = {".txt", ".log", ".json", ".xml", ".gaml", ".md"}

DELIMITERS = ";,\t|"
# Below this, a delimited `.txt` is a key/value list rather than a table:
# simulationParameters.txt is two tab-separated columns and charts nothing.
MIN_TABLE_COLUMNS = 3
PROBE_LINES = 3


def _kind(path: Path) -> OutputKind:
    """What can be done with the file — decided on its content, not its name.

    A `.csv` is taken at its word; any other text file has to prove it is a
    table, because the model drops prose next to its tables in the same folder.
    """
    suffix = path.suffix.lower()
    if suffix in TABLE_SUFFIXES:
        return OutputKind.TABLE
    if suffix in TEXT_SUFFIXES:
        return OutputKind.TABLE if _looks_tabular(path) else OutputKind.TEXT
    return OutputKind.BINARY


def _looks_tabular(path: Path) -> bool:
    """Several lines split into the same number of columns, three at least."""
    try:
        with path.open("rb") as handle:
            head = [handle.readline(8192).decode("utf-8", errors="replace")
                    for _ in range(PROBE_LINES)]
    except OSError:
        return False

    lines = [line.rstrip("\r\n") for line in head if line.strip()]
    if len(lines) < 2:
        return False

    delimiter = max(DELIMITERS, key=lines[0].count)
    counts = {line.count(delimiter) for line in lines}
    return len(counts) == 1 and counts.pop() >= MIN_TABLE_COLUMNS - 1


class FileOutputStore:
    """Adapter over the run's output directory."""

    def _directory(self, run: dict) -> Path | None:
        candidates = [settings.MAELIA_OUTPUT_ROOT / str(run["id"])]
        announced = run.get("output_dir")
        if announced:
            candidates.append(Path(announced))
        return next((c for c in candidates if c.is_dir()), None)

    async def list_files(self, run: dict) -> list[OutputFile]:
        return await asyncio.to_thread(self._list_files, run)

    def _list_files(self, run: dict) -> list[OutputFile]:
        directory = self._directory(run)
        if directory is None:
            return []
        return [
            OutputFile(name=path.name, size=path.stat().st_size, kind=_kind(path))
            for path in sorted(directory.iterdir())
            if path.is_file()
        ]

    async def read(self, run: dict, name: str) -> bytes:
        return await asyncio.to_thread(self._read, run, name)

    def _read(self, run: dict, name: str) -> bytes:
        directory = self._directory(run)
        if directory is None:
            raise NotFoundError(f"aucune sortie pour le run {run['id']}")

        # Resolved and compared to the directory: a name like `../../secret`
        # must not escape the run's own outputs.
        target = (directory / name).resolve()
        if not target.is_file() or directory.resolve() not in target.parents:
            raise NotFoundError(f"sortie inconnue : {name}")
        return target.read_bytes()
