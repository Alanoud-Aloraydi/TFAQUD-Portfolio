"""Allow a named appointment type outside the preset kinds.

Revision ID: 0013
Revises: 0012
"""

from alembic import op
import sqlalchemy as sa

revision = "0013"
down_revision = "0012"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Add a bounded custom type while retaining existing visit kinds."""
    op.add_column("appointment", sa.Column("other_kind", sa.Text()))
    op.drop_constraint(
        op.f("ck_appointment_kind"), "appointment", type_="check"
    )
    op.create_check_constraint(
        op.f("ck_appointment_kind"), "appointment",
        "kind IN ('follow_up', 'test', 'imaging', 'remote', 'other')",
    )
    op.create_check_constraint(
        op.f("ck_appointment_other_kind_shape"), "appointment",
        "(kind = 'other' AND other_kind IS NOT NULL AND "
        "length(btrim(other_kind)) > 0 AND "
        "char_length(other_kind) <= 80) OR "
        "(kind <> 'other' AND other_kind IS NULL)",
    )


def downgrade() -> None:
    """Restore the preset-only kind constraint."""
    op.execute(
        "UPDATE appointment SET kind = 'follow_up' WHERE kind = 'other'"
    )
    op.drop_constraint(
        op.f("ck_appointment_other_kind_shape"),
        "appointment", type_="check"
    )
    op.drop_constraint(
        op.f("ck_appointment_kind"), "appointment", type_="check"
    )
    op.create_check_constraint(
        op.f("ck_appointment_kind"), "appointment",
        "kind IN ('follow_up', 'test', 'imaging', 'remote')",
    )
    op.drop_column("appointment", "other_kind")
