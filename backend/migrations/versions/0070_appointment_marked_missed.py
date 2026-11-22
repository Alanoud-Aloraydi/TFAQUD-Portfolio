"""A visit someone marked «فائت» from «السجل».

`appointment.marked_missed`: the person chose «فائت» for a visit whose time
passed. It stays open (`scheduled`, so «حضرت» or «ملغى» can still be
chosen for it), and every page shows it missed at once, not only once it
left «يحتاج انتباهك» two days later. Only an open visit can be marked so.

Revision ID: 0070
Revises: 0069
"""
import sqlalchemy as sa
from alembic import op

revision = "0070"
down_revision = "0069"
branch_labels = None
depends_on = None

_RULE = "ck_appointment_marked_missed"


def upgrade() -> None:
    op.add_column(
        "appointment",
        sa.Column(
            "marked_missed",
            sa.Boolean(),
            server_default=sa.false(),
            nullable=False,
        ),
    )
    op.create_check_constraint(
        op.f(_RULE), "appointment", "NOT marked_missed OR status = 'scheduled'"
    )


def downgrade() -> None:
    op.drop_constraint(op.f(_RULE), "appointment", type_="check")
    op.drop_column("appointment", "marked_missed")
