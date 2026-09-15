"""Catalog tables: what the model expects as input, and what it exposes as knobs."""

from datetime import datetime
from typing import Any

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.shared.database import Base


class DataSpecRow(Base):
    """One kind of input file expected by the model.

    The id is a stable string (`agri.culture.reglesDeDecisions`) rather than a
    UUID: seeds, dependencies and `requiredIf` all refer to it by name.
    """

    __tablename__ = "data_spec"

    id: Mapped[str] = mapped_column(String(120), primary_key=True)
    label: Mapped[str] = mapped_column(String(200))
    module: Mapped[str] = mapped_column(String(40), index=True)
    kind: Mapped[str] = mapped_column(String(20))  # CSV | SHAPEFILE | IMAGE | TEXT

    # Path relative to the territory: <relative_dir>/<file_name or instance_key>.
    # file_name is NULL for dynamic-name families (2018.csv, prixVentesSC1.csv).
    relative_dir: Mapped[str] = mapped_column(String(300))
    file_name: Mapped[str | None] = mapped_column(String(160), nullable=True)
    file_name_pattern: Mapped[str | None] = mapped_column(String(160), nullable=True)

    # Tabular format (CSV specs only).
    orientation: Mapped[str | None] = mapped_column(String(30), nullable=True)
    delimiter: Mapped[str] = mapped_column(String(1), default=";")
    has_header: Mapped[bool] = mapped_column(Boolean, default=True)
    matrix_value_start_index: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Applicability and dependencies.
    required: Mapped[bool] = mapped_column(Boolean, default=True)
    required_if: Mapped[str | None] = mapped_column(Text, nullable=True)
    depends_on: Mapped[str | None] = mapped_column(Text, nullable=True)  # '|'-separated ids

    gaml_source: Mapped[str | None] = mapped_column(String(200), nullable=True)
    origin: Mapped[str] = mapped_column(String(10), default="SEED")  # SEED | USER
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    fields: Mapped[list["FieldSpecRow"]] = relationship(
        back_populates="data_spec", cascade="all, delete-orphan", order_by="FieldSpecRow.position"
    )


class FieldSpecRow(Base):
    """One column of a tabular file."""

    __tablename__ = "field_spec"
    # A field's identity is its POSITION, not its name: a transposed file may
    # legitimately repeat row labels (several operations of the same kind per ITK
    # in reglesDeDecisions.csv, see plusieursTravauxDuSolParITK).
    __table_args__ = (
        UniqueConstraint("data_spec_id", "position", name="ux_field_spec_position"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    data_spec_id: Mapped[str] = mapped_column(
        String(120), ForeignKey("data_spec.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(120))
    label: Mapped[str | None] = mapped_column(String(200), nullable=True)
    type: Mapped[str] = mapped_column(String(20), default="STRING")  # STRING|INT|FLOAT|BOOL|DATE
    required: Mapped[bool] = mapped_column(Boolean, default=False)
    unit: Mapped[str | None] = mapped_column(String(40), nullable=True)
    allowed_values: Mapped[str | None] = mapped_column(Text, nullable=True)  # '|'-separated
    # Business foreign key: this field references the id of another file.
    references_data_spec: Mapped[str | None] = mapped_column(String(120), nullable=True)
    position: Mapped[int] = mapped_column(Integer, default=0)

    data_spec: Mapped[DataSpecRow] = relationship(back_populates="fields")


class ParameterSpecRow(Base):
    """One scenario parameter exposed by the launcher.

    Keyed by GAML name: that is the key gama-server expects in a `load`, so any
    other identifier would only add a translation step.
    """

    __tablename__ = "parameter_spec"

    name: Mapped[str] = mapped_column(String(120), primary_key=True)
    label: Mapped[str] = mapped_column(String(200))
    group: Mapped[str] = mapped_column(String(80), index=True)
    type: Mapped[str] = mapped_column(String(20))
    # Kept as JSON: a default may be a boolean, a number, a string or a list.
    default: Mapped[Any | None] = mapped_column(JSONB, nullable=True)
    allowed_values: Mapped[str | None] = mapped_column(Text, nullable=True)  # '|'-separated
    # Imposed by the platform: overriding it in a scenario has no effect.
    system: Mapped[bool] = mapped_column(Boolean, default=False)
    editable: Mapped[bool] = mapped_column(Boolean, default=True)
    # '<data_spec_id>#<field>' : ou lire les valeurs acceptables.
    options_from: Mapped[str | None] = mapped_column(String(200), nullable=True)
    # '<autre parametre> == true' : condition d'activite.
    enabled_if: Mapped[str | None] = mapped_column(String(300), nullable=True)
    origin: Mapped[str] = mapped_column(String(10), default="SEED")


class OutputSpecRow(Base):
    """One family of result files, and the guard that decides it is written.

    Keyed by the switch that commands it (`sorties_eau`) when there is one, so
    the id reads the same in the catalog, in a scenario and in the GAML.
    """

    __tablename__ = "output_spec"

    id: Mapped[str] = mapped_column(String(160), primary_key=True)
    label: Mapped[str] = mapped_column(String(200))
    theme: Mapped[str] = mapped_column(String(80), index=True)
    module: Mapped[str] = mapped_column(String(40), index=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    # The scenario parameter that switches it on, when the launcher exposes one.
    flag: Mapped[str | None] = mapped_column(String(120), nullable=True)
    # Files stay with their spec: one to three per output, never queried on
    # their own, and always read together. A child table would buy nothing.
    files: Mapped[Any] = mapped_column(JSONB, default=list)

    # Guard, twice over: evaluable, and verbatim. `exact` is false when the
    # translation had to drop a term the condition language cannot express.
    produced_if: Mapped[str | None] = mapped_column(Text, nullable=True)
    guard_source: Mapped[str | None] = mapped_column(Text, nullable=True)
    exact: Mapped[bool] = mapped_column(Boolean, default=True)

    gaml_source: Mapped[str | None] = mapped_column(String(200), nullable=True)
    origin: Mapped[str] = mapped_column(String(10), default="SEED")
