"""Content-addressed blob storage on MinIO.

The authoritative tier: what GAMA ends up reading comes from here. Bytes are
stored under their own sha256, which buys deduplication for free — two versions
with identical content share one object, and a new shapefile version that only
changes the `.dbf` stores a single new blob.

The MinIO client is synchronous, so every call goes through `asyncio.to_thread`:
blocking the event loop would freeze the whole worker.
"""

import asyncio
import io
import logging

from minio import Minio
from minio.error import S3Error

from app.contexts.dataset.domain.services import content_hash
from app.shared.config import settings

log = logging.getLogger("maelia.blobs")

# Two levels of prefix keep the bucket browsable: thousands of objects in a flat
# namespace are painful to inspect.
PREFIX = "blobs"


def object_key(digest: str) -> str:
    return f"{PREFIX}/{digest[:2]}/{digest[2:4]}/{digest}"


class MinioBlobStore:
    """Satisfies `BlobStore` without inheriting from it: `Protocol` is structural."""

    def __init__(self, client: Minio | None = None, bucket: str | None = None) -> None:
        self._client = client or Minio(
            settings.MINIO_ENDPOINT,
            access_key=settings.MINIO_ACCESS_KEY,
            secret_key=settings.MINIO_SECRET_KEY,
            secure=settings.MINIO_SECURE,
        )
        self._bucket = bucket or settings.MINIO_BUCKET

    async def put(self, payload: bytes) -> tuple[str, int]:
        """Store the bytes and return (content_hash, size).

        Idempotent: an already-present digest is not rewritten. That is what makes
        publishing the same file twice cheap.
        """
        digest = content_hash(payload)
        size = len(payload)

        if await self.exists(digest):
            return digest, size

        def _upload() -> None:
            self._client.put_object(
                self._bucket, object_key(digest), io.BytesIO(payload), size
            )

        await asyncio.to_thread(_upload)
        log.debug("blob stored %s (%d bytes)", digest[:12], size)
        return digest, size

    async def get(self, content_hash_: str) -> bytes:
        def _download() -> bytes:
            response = self._client.get_object(self._bucket, object_key(content_hash_))
            try:
                return response.read()
            finally:
                response.close()
                response.release_conn()

        return await asyncio.to_thread(_download)

    async def exists(self, content_hash_: str) -> bool:
        def _stat() -> bool:
            try:
                self._client.stat_object(self._bucket, object_key(content_hash_))
            except S3Error as exc:
                if exc.code in {"NoSuchKey", "NoSuchObject"}:
                    return False
                raise
            return True

        return await asyncio.to_thread(_stat)
