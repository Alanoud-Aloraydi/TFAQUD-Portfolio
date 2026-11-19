"""Doses are kept three months: the scheduled tick deletes the older ones
every minute, by these indexes.

Revision ID: 0065
Revises: 0064
"""
from alembic import op

revision = "0065"
down_revision = "0064"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_index(
        op.f("ix_medication_dose_record_scheduled_on"),
        "medication_dose_record",
        ["scheduled_on"],
    )
    op.create_index(
        op.f("ix_medication_extra_dose_taken_at"),
        "medication_extra_dose",
        ["taken_at"],
    )


def downgrade() -> None:
    op.drop_index(
        op.f("ix_medication_extra_dose_taken_at"),
        table_name="medication_extra_dose",
    )
    op.drop_index(
        op.f("ix_medication_dose_record_scheduled_on"),
        table_name="medication_dose_record",
    )
