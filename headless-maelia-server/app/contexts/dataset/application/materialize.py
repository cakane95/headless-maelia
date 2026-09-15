"""Includes materialisation: an isolated input set per run.

Essential as soon as several simulations run in parallel. MAELIA does not merely
READ its includes: it rewrites some of them mid-run (`blocsDonnees.csv`,
`blocsDonnees_cor.csv`...). Two runs pointing at the same directory would corrupt
each other — with no error, and silently wrong results.

Each run gets a copy of the territory under `includes/.runs/<runId>/`, and
`cheminModeleVersDonnees` is pointed at it. The baseline `includes/<territory>`
thus becomes a read-only source.

The project's dataset versions are then **overlaid** onto that copy (the
`overlays` argument): this is the extension point for the project domain.
"""

import logging
import shutil
from collections.abc import Iterable
from dataclasses import dataclass
from pathlib import Path

from app.shared.config import settings

log = logging.getLogger("maelia.includes")

# Sub-directory holding the working copies. The leading dot sets it apart from
# real territories, and .gitignore excludes it from the repository.
RUNS_DIRNAME = ".runs"


@dataclass(frozen=True, slots=True)
class OverlayFile:
    """A file to overlay on the baseline.

    `content` holds the EXACT bytes of the published version: never regenerated,
    only copied.
    """

    relative_dir: str   # 'modeleAgricole/culture'
    file_name: str      # 'reglesDeDecisions.csv'
    content: bytes


def includes_root() -> Path:
    return settings.MAELIA_PROJECT_DIR / "includes"


def run_includes_dir(run_id: str) -> Path:
    return includes_root() / RUNS_DIRNAME / run_id


def materialize(
    run_id: str,
    territory: str,
    overlays: Iterable[OverlayFile] = (),
    baseline: bool = True,
) -> str:
    """Build the input set of a run, in a directory of its own.

    `baseline=True` starts from a copy of `includes/<territory>`: that is the
    **test bench**, which exercises GAMA on the data shipped with the model.

    `baseline=False` starts from nothing: a **project** runs on its own files
    and on nothing else. Copying a shipped territory underneath would silently
    fill the gaps with test data — and the results would describe neither the
    project nor the fixture.

    Returns the value to hand to `cheminModeleVersDonnees`: the PARENT of the
    directory, because the model appends `nomDecoupageZonePourLectureFichiers`.
    """
    target_parent = run_includes_dir(run_id)
    target = target_parent / territory

    if target_parent.exists():
        shutil.rmtree(target_parent)
    target.parent.mkdir(parents=True, exist_ok=True)

    if baseline:
        source = includes_root() / territory
        if not source.is_dir():
            raise FileNotFoundError(f"unknown territory: {source}")
        shutil.copytree(source, target)
    else:
        target.mkdir(parents=True)

    overlaid = 0
    for overlay in overlays:
        destination = target / overlay.relative_dir / overlay.file_name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(overlay.content)
        overlaid += 1

    log.info(
        "includes materialised for %s: %s (%d project file(s), baseline=%s)",
        run_id, target, overlaid, baseline,
    )
    # The trailing slash matters: the model concatenates the territory name to it.
    return f"{target_parent.as_posix()}/"


def cleanup(run_id: str) -> None:
    """Remove the working copy. Best effort: it must never fail a run."""
    directory = run_includes_dir(run_id)
    try:
        if directory.exists():
            shutil.rmtree(directory)
    except OSError as exc:
        log.warning("could not clean up includes for %s: %s", run_id, exc)
