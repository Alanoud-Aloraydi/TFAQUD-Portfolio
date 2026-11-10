"""Record who last edited an appointment, for tracking.

The service, the routes and the queries already save and show
`appointment.updated_by_account_id` (who last edited it or set its
status), but the column was never made: every new appointment, edit and
status failed with a server error, and so did listing a circle's
appointments once it had one. Like 0021 for measurement plan versions.

Revision ID: 0027
Revises: 0026
"""

from alembic import op
import sqlalchemy as sa

revision = "0027"
down_revision = "0026"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "appointment", sa.Column("updated_by_account_id", sa.Uuid())
    )
    op.create_foreign_key(
        op.f("fk_appointment_updated_by_account_id_account"),
        "appointment",
        "account",
        ["updated_by_account_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint(
        op.f("fk_appointment_updated_by_account_id_account"),
        "appointment",
        type_="foreignkey",
    )
    op.drop_column("appointment", "updated_by_account_id")
