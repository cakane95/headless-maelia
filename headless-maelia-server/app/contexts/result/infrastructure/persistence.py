"""Saved readings of a project's outputs.

A chart configuration is cheap to rebuild by hand — once. Rebuilding the seven
readings of a report on every run is not: the point of a saved view is that the
same reading applies to a new execution without being re-typed.
"""

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, ForeignKey, String, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB, UUID

from sqlalchemy.orm import Mapped, mapped_column

from app.shared.database import Base


class OutputViewRow(Base):
    """One saved reading: a file, a chart type, and the query behind it."""

    __tablename__ = "output_view"
    __table_args__ = (
        UniqueConstraint("project_id", "name", name="uq_output_view_name"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    project_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("project.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(160))
    file_name: Mapped[str] = mapped_column(String(255))
    chart: Mapped[str] = mapped_column(String(20))
    # La requête telle quelle : axe, mesures, répartition, agrégat, filtres. Le
    # schéma vit dans le domaine, pas dans des colonnes qu'il faudrait migrer à
    # chaque type de graphique ajouté.
    query: Mapped[dict[str, Any]] = mapped_column(JSONB)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
