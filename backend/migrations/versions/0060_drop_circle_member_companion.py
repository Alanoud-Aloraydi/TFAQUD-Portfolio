"""Take the companion flag off the membership again.

0059 stored «مرافق» on the membership, for the whole circle. The circle
does not work that way: a companion is chosen for one visit, so «حضرت»
asks the people on that visit's own companion list and nobody else. The
column was never read, and a member marked there would have been asked
about visits they never went to.

Nothing is lost: who accompanies each visit is in `appointment_companion`,
where it always was.

Revision ID: 0060
Revises: 0059
"""
import sqlalchemy as sa
from alembic import op

revision = "0060"
down_revision = "0059"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_column("care_circle_manager", "is_companion")


def downgrade() -> None:
    op.add_column(
        "care_circle_manager",
        sa.Column(
            "is_companion",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )
