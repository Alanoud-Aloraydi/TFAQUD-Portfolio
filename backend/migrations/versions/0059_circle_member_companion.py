"""Mark a circle member as a companion («مرافق»).

A member's three edit flags say what they may change; none of them says
whether they go with the patient to a visit. «حضرت» belongs to whoever
was there, so the circle now stores that: the leader marks the members
who accompany the patient.

Off for everyone at first: a circle keeps working, and the leader says
who accompanies. The patient needs no flag — they are always at their own
visit.

Revision ID: 0059
Revises: 0058
"""
import sqlalchemy as sa
from alembic import op

revision = "0059"
down_revision = "0058"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "care_circle_manager",
        sa.Column(
            "is_companion",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )


def downgrade() -> None:
    op.drop_column("care_circle_manager", "is_companion")
