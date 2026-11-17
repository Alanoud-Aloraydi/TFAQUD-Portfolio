"""How long before a visit its own reminder comes.

Every appointment was reminded twice: the day before, and a fixed two
hours before its time. Two hours suits a clinic across the city and not a
room downstairs, so each visit now carries its own lead, chosen when it
is booked.

Sixty minutes for the visits saved until now, which is the default the
form offers; the day-before reminder is untouched.

Revision ID: 0061
Revises: 0060
"""
import sqlalchemy as sa
from alembic import op

revision = "0061"
down_revision = "0060"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "appointment",
        sa.Column(
            "reminder_lead_minutes",
            sa.SmallInteger(),
            nullable=False,
            server_default=sa.text("60"),
        ),
    )


def downgrade() -> None:
    op.drop_column("appointment", "reminder_lead_minutes")
