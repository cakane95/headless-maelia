"""Simulation run table."""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.shared.database import Base


class SimulationRunRow(Base):
    __tablename__ = "simulation_run"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("project.id", ondelete="CASCADE"), nullable=True, index=True
    )
    scenario_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("scenario.id", ondelete="SET NULL"), nullable=True
    )

    label: Mapped[str] = mapped_column(String(200))
    model_path: Mapped[str] = mapped_column(String(500))
    experiment: Mapped[str] = mapped_column(String(120))
    territory: Mapped[str | None] = mapped_column(String(80), nullable=True)
    parameters: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list)

    # Resolution FROZEN at launch: {dataset_id: version_id} for EVERY applicable
    # dataset, not only the pinned ones. That is what keeps a run reproducible
    # even after newer versions are published.
    resolved_versions: Mapped[dict[str, Any]] = mapped_column(JSONB, default=dict)

    status: Mapped[str] = mapped_column(String(20), default="PENDING", index=True)
    cycle: Mapped[int | None] = mapped_column(Integer, nullable=True)
    current_date: Mapped[str | None] = mapped_column(String(20), nullable=True)
    error: Mapped[str | None] = mapped_column(Text, nullable=True)
    output_dir: Mapped[str | None] = mapped_column(String(500), nullable=True)
    artifacts: Mapped[list[dict[str, Any]]] = mapped_column(JSONB, default=list)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
