"""valeur declaree par le launcher execute

Revision ID: d31c8a7f5e62
Revises: b2f7c40e19aa
"""

from collections.abc import Sequence

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = 'd31c8a7f5e62'
down_revision: str | None = 'b2f7c40e19aa'
branch_labels: Sequence[str] | None = None
depends_on: Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        'parameter_spec',
        sa.Column(
            'launcher_default',
            postgresql.JSONB(astext_type=sa.Text()),
            nullable=True,
        ),
    )


def downgrade() -> None:
    op.drop_column('parameter_spec', 'launcher_default')
