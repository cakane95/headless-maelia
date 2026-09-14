"""Result context boundary.

One port, because there is one thing the domain cannot do: reach the bytes a run
produced. Today they sit in the model tree; ingesting them into object storage
later changes this adapter and nothing else.
"""

from typing import Protocol

from app.contexts.result.domain.models import OutputFile


class OutputStore(Protocol):
    """Read access to the files produced by a run."""

    async def list_files(self, run: dict) -> list[OutputFile]:
        """Files of this run, or an empty list if it produced none."""
        ...

    async def read(self, run: dict, name: str) -> bytes:
        """Bytes of one file. Raises NotFoundError if it is not a file of this run."""
        ...
