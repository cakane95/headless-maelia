"""CSV codec — reads and writes the two orientations MAELIA uses.

Three things make this trickier than a `csv.reader` call:

* **Transposed files.** In `especesCultivees.csv` or `reglesDeDecisions.csv` field
  names sit in the first column and each following column describes one entity.
  Some of them also insert a meta column between the field name and the values,
  hence `matrix_value_start_index`.
* **Repeated field names.** A transposed file may legitimately repeat a row label
  (several operations of the same kind per ITK). A field's identity is therefore
  its POSITION, and rows are keyed by index, never by name.
* **The bytes matter.** A version published from an edited draft is serialised
  once and then frozen: whatever `encode` produces is what GAMA will read. So the
  codec must reproduce the *physical* file — encoding, BOM, line terminator,
  trailing newline, meta columns — not merely its logical content.

Hence `Dialect`: everything physical travels with the table, so that

    encode(decode(raw, spec), spec) == raw

holds byte for byte. `tests/integration/test_codec_roundtrip.py` checks it on
every file actually shipped with the model.
"""

import csv
import io
from dataclasses import dataclass, field

from app.contexts.catalog.domain.models import DataSpec, Orientation

# The model ships files in both encodings; UTF-8 first, latin-1 never fails.
ENCODINGS = ("utf-8-sig", "utf-8", "latin-1")
BOM = "﻿"

# Line terminators, named rather than escaped: the shipped data uses all three.
CR = chr(13)
LF = chr(10)
CRLF = CR + LF


@dataclass(frozen=True, slots=True)
class Dialect:
    """The physical shape of the source file, needed to rebuild it identically."""

    encoding: str = "utf-8"
    bom: bool = False
    line_terminator: str = "\n"
    trailing_newline: bool = True
    # Content of the meta columns of a transposed file (between the field name and
    # the values). Restoring them empty would silently rewrite the file.
    meta: tuple[tuple[str, ...], ...] = ()


@dataclass(frozen=True, slots=True)
class Table:
    """Decoded content of a tabular file.

    `columns` are the field names in file order — duplicates included. `rows` hold
    the values positionally, so a repeated name never loses a value.
    """

    columns: tuple[str, ...]
    rows: tuple[tuple[str, ...], ...]
    dialect: Dialect = field(default_factory=Dialect)

    @staticmethod
    def record_keys(columns: tuple[str, ...]) -> list[str]:
        """Keys of the name-based view, duplicates suffixed (`NAME__2`).

        Shared by `as_records` and `from_records` so the two stay inverse.
        """
        keys, seen = [], {}
        for column in columns:
            seen[column] = seen.get(column, 0) + 1
            keys.append(column if seen[column] == 1 else f"{column}__{seen[column]}")
        return keys

    def as_records(self) -> list[dict[str, str]]:
        """Row view keyed by name, for display and validation.

        A duplicated name is suffixed so nothing is silently dropped. The
        authoritative form stays `rows`, which is positional.
        """
        keys = self.record_keys(self.columns)
        return [
            {k: v.strip() for k, v in zip(keys, row, strict=False)} for row in self.rows
        ]

    @classmethod
    def from_records(
        cls,
        records: list[dict[str, str]],
        columns: tuple[str, ...],
        dialect: "Dialect | None" = None,
    ) -> "Table":
        """Inverse of `as_records`, against a known column order.

        The order comes from the caller, never from the record keys: a draft is
        stored as JSONB, whose key order the database is free to normalise.
        Rebuilding columns from those keys would silently reorder the file.
        """
        keys = cls.record_keys(columns)
        rows = tuple(
            tuple(record.get(key, "") for key in keys) for record in records
        )
        return cls(columns=columns, rows=rows, dialect=dialect or Dialect())


def _decode_text(raw: bytes) -> tuple[str, str, bool]:
    """Return (text, encoding, had_bom). The BOM is stripped from the text."""
    for encoding in ENCODINGS:
        try:
            text = raw.decode(encoding)
        except UnicodeDecodeError:
            continue
        if encoding == "utf-8-sig":
            return text, "utf-8", raw.startswith(b"\xef\xbb\xbf")
        return text, encoding, False
    return raw.decode("latin-1", errors="replace"), "latin-1", False


def _line_terminator(text: str) -> str:
    """joursParMois.csv still uses bare CR (classic Mac endings).

    All three forms exist in the shipped data, so all three must survive the trip.
    """
    if CRLF in text:
        return CRLF
    if CR in text:
        return CR
    return LF


def _sniff_dialect(text: str, encoding: str, bom: bool) -> Dialect:
    return Dialect(
        encoding=encoding,
        bom=bom,
        line_terminator=_line_terminator(text),
        trailing_newline=text.endswith((LF, CR)),
    )

def decode(raw: bytes, spec: DataSpec) -> Table:
    """Turn the bytes of a file into a table, following the spec's orientation."""
    text, encoding, bom = _decode_text(raw)
    dialect = _sniff_dialect(text, encoding, bom)

    # Cells are kept verbatim: stripping here would rewrite the file on the way
    # back out. Trimming happens in `as_records`, for display and validation only.
    grid = [
        row for row in csv.reader(io.StringIO(text, newline=""), delimiter=spec.delimiter)
    ]
    if not grid:
        return Table(columns=(), rows=(), dialect=dialect)

    if spec.orientation is Orientation.FIELDS_AS_ROWS:
        return _decode_transposed(grid, spec, dialect)
    return _decode_columns(grid, dialect)


def _decode_columns(grid: list[list[str]], dialect: Dialect) -> Table:
    header, *body = grid
    columns = tuple(header)
    # Rows keep their own width: padding them would add cells the file never had.
    return Table(columns=columns, rows=tuple(tuple(row) for row in body), dialect=dialect)


def _decode_transposed(grid: list[list[str]], spec: DataSpec, dialect: Dialect) -> Table:
    """Field names in column 0; one entity per following column.

    `matrix_value_start_index` says where the values begin — 2 when a meta column
    sits between the name and the data. Those meta cells are carried in the
    dialect so publication restores them as they were.
    """
    start = spec.matrix_value_start_index or 1
    columns = tuple(line[0] if line else "" for line in grid)
    width = max((len(line) for line in grid), default=0)

    # Only populate `meta` when meta columns actually exist: a tuple of empty
    # tuples would make two equivalent tables compare unequal.
    meta = (
        tuple(
            tuple(line[1:start]) + ("",) * (start - 1 - len(line[1:start]))
            for line in grid
        )
        if start > 1
        else ()
    )

    # One row per entity: read the grid column-wise.
    rows = tuple(
        tuple(line[index] if index < len(line) else "" for line in grid)
        for index in range(start, width)
    )
    return Table(
        columns=columns,
        rows=rows,
        dialect=Dialect(
            encoding=dialect.encoding,
            bom=dialect.bom,
            line_terminator=dialect.line_terminator,
            trailing_newline=dialect.trailing_newline,
            meta=meta,
        ),
    )


def encode(table: Table, spec: DataSpec) -> bytes:
    """Serialise a table back to bytes, in the spec's orientation.

    Called exactly ONCE, when a draft is published. Afterwards the bytes are the
    reference and are only ever copied.
    """
    dialect = table.dialect
    if spec.orientation is Orientation.FIELDS_AS_ROWS:
        grid = _encode_transposed(table, spec)
    else:
        grid = [list(table.columns), *[list(row) for row in table.rows]]

    buffer = io.StringIO(newline="")
    writer = csv.writer(
        buffer,
        delimiter=spec.delimiter,
        lineterminator=dialect.line_terminator,
        quoting=csv.QUOTE_MINIMAL,
    )
    writer.writerows(grid)

    text = buffer.getvalue()
    if not dialect.trailing_newline:
        text = text.rstrip("\r\n")
    if dialect.bom:
        text = BOM + text

    return text.encode(dialect.encoding)


def _encode_transposed(table: Table, spec: DataSpec) -> list[list[str]]:
    start = spec.matrix_value_start_index or 1
    meta = table.dialect.meta
    grid: list[list[str]] = []

    for position, column in enumerate(table.columns):
        line = [column]
        # Restore the meta cells exactly as they were read.
        line.extend(meta[position] if position < len(meta) else [""] * (start - 1))
        line.extend(row[position] if position < len(row) else "" for row in table.rows)
        grid.append(line)

    return grid
