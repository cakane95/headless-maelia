"""Scenario table: parameter deltas plus pinned data versions."""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.shared.database import Base


class ScenarioRow(Base):
    __tablename__ = "scenario"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("project.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(200))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Only the DELTAS from the launcher defaults.
    parameter_values: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)

    # Pinned versions: {dataset_id: version_id}. Anything unpinned follows the
    # dataset's latest valid version — hence "pin only what must vary".
    dataset_pins: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )
