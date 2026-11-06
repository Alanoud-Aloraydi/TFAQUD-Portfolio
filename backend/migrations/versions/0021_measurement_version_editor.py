"""Record who made each measurement plan version, for tracking.

Mirrors the medication plan version's own created_by_account_id, which
already exists; measurement plan versions never had it.

Revision ID: 0021
Revises: 0020
"""

from alembic import op
import sqlalchemy as sa

revision = "0021"
down_revision = "0020"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "measurement_plan_version",
        sa.Column("created_by_account_id", sa.Uuid()),
    )
    op.create_foreign_key(
        op.f(
            "fk_measurement_plan_version_created_by_account_id_account"
        ),
        "measurement_plan_version",
        "account",
        ["created_by_account_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.drop_constraint(
        op.f(
            "fk_measurement_plan_version_created_by_account_id_account"
        ),
        "measurement_plan_version",
        type_="foreignkey",
    )
    op.drop_column("measurement_plan_version", "created_by_account_id")
