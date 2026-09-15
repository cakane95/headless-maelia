"""output catalog

Revision ID: b2f7c40e19aa
Revises: ae3a19d7af44
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = 'b2f7c40e19aa'
down_revision: str | None = 'ae3a19d7af44'
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        'output_spec',
        sa.Column('id', sa.String(length=160), nullable=False),
        sa.Column('label', sa.String(length=200), nullable=False),
        sa.Column('theme', sa.String(length=80), nullable=False),
        sa.Column('module', sa.String(length=40), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('flag', sa.String(length=120), nullable=True),
        sa.Column('files', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('produced_if', sa.Text(), nullable=True),
        sa.Column('guard_source', sa.Text(), nullable=True),
        sa.Column('exact', sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column('gaml_source', sa.String(length=200), nullable=True),
        sa.Column('origin', sa.String(length=10), nullable=False, server_default='SEED'),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_output_spec_theme'), 'output_spec', ['theme'])
    op.create_index(op.f('ix_output_spec_module'), 'output_spec', ['module'])


def downgrade() -> None:
    op.drop_index(op.f('ix_output_spec_module'), table_name='output_spec')
    op.drop_index(op.f('ix_output_spec_theme'), table_name='output_spec')
    op.drop_table('output_spec')
