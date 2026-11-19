"""«سجّل جرعة الآن»: doses taken outside the dose times.

A medicine can now have no dose time at all; its doses, and any dose on top
of the scheduled ones, are kept here, never as a scheduled dose's record.

Revision ID: 0064
Revises: 0063
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0064"
down_revision = "0063"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "medication_extra_dose",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "medication_plan_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("medication_plan.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("taken_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("dose_value", sa.Numeric(10, 3), nullable=False),
        sa.Column("dose_unit", sa.Text(), nullable=False),
        sa.Column(
            "recorded_by_account_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("account.id", ondelete="SET NULL"),
        ),
        sa.Column(
            "recorded_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.CheckConstraint("dose_value > 0", name="positive_dose"),
        sa.CheckConstraint(
            "dose_unit IN "
            "('tablet', 'capsule', 'mL', 'drop', 'puff', 'unit')",
            name="dose_unit",
        ),
        sa.CheckConstraint(
            "taken_at <= recorded_at", name="taken_before_recorded"
        ),
    )
    op.create_index(
        op.f("ix_medication_extra_dose_medication_plan_id"),
        "medication_extra_dose",
        ["medication_plan_id"],
    )
    op.create_index(
        op.f("ix_medication_extra_dose_recorded_by_account_id"),
        "medication_extra_dose",
        ["recorded_by_account_id"],
    )


def downgrade() -> None:
    op.drop_table("medication_extra_dose")
