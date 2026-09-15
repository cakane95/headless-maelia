"""The codec must round-trip the real files.

A version published from an edited draft is serialised ONCE, then frozen. If
`encode(decode(x)) != x`, that serialisation silently rewrites the file the model
will read — and the results change for a reason nobody asked for.

These tests run against every file actually shipped under `includes/`.
"""

import json
import pathlib

import pytest

from app.contexts.catalog.domain.models import DataSpec, FileKind, Orientation
from app.contexts.dataset.domain.codec import decode, encode

SEED = (
    pathlib.Path(__file__).resolve().parents[2]
    / "app/contexts/catalog/infrastructure/seed/dataspecs.json"
)
INCLUDES = pathlib.Path("/usr/lib/gama/workspace/gama-models/MAELIA_1.4.29_GAMA_2025-06/includes")


def _real_csv_specs() -> list[tuple[str, DataSpec, pathlib.Path]]:
    if not SEED.is_file() or not INCLUDES.is_dir():
        return []

    found = []
    for entry in json.loads(SEED.read_text(encoding="utf-8")):
        if entry["kind"] != "CSV" or not entry["file_name"]:
            continue
        for territory in sorted(p for p in INCLUDES.iterdir() if p.is_dir()):
            path = territory / entry["relative_dir"] / entry["file_name"]
            if path.is_file():
                spec = DataSpec(
                    id=entry["id"], label=entry["label"], module=entry["module"],
                    kind=FileKind.CSV, relative_dir=entry["relative_dir"],
                    file_name=entry["file_name"],
                    orientation=Orientation(entry["orientation"])
                    if entry.get("orientation") else None,
                    delimiter=entry.get("delimiter") or ";",
                    matrix_value_start_index=entry.get("matrix_value_start_index"),
                )
                found.append((entry["id"], spec, path))
                break
    return found


REAL_FILES = _real_csv_specs()


@pytest.mark.skipif(not REAL_FILES, reason="model files not mounted")
@pytest.mark.parametrize(
    ("spec_id", "spec", "path"), REAL_FILES, ids=[f[0] for f in REAL_FILES]
)
def test_decode_then_encode_preserves_the_bytes(spec_id, spec, path):
    """Byte-for-byte: this is what the model reads."""
    original = path.read_bytes()
    assert encode(decode(original, spec), spec) == original


@pytest.mark.skipif(not REAL_FILES, reason="model files not mounted")
@pytest.mark.parametrize(
    ("spec_id", "spec", "path"), REAL_FILES, ids=[f[0] for f in REAL_FILES]
)
def test_decode_is_stable(spec_id, spec, path):
    """A second pass must find the same table."""
    original = path.read_bytes()
    once = decode(original, spec)
    assert decode(encode(once, spec), spec) == once
