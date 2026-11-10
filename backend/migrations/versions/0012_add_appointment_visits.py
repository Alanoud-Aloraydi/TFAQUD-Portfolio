"""Add written and voice visit notes.

Revision ID: 0012
Revises: 0011
"""

from alembic import op
import sqlalchemy as sa

revision = "0012"
down_revision = "0011"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Store a single bounded report for each appointment."""
    op.create_table(
        "appointment_visit",
        sa.Column("appointment_id", sa.Uuid(), nullable=False),
        sa.Column("summary", sa.Text()),
        sa.Column("recommendations", sa.Text()),
        sa.Column("follow_up", sa.Text()),
        sa.Column("audio", sa.LargeBinary()),
        sa.Column("updated_by_account_id", sa.Uuid()),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True),
            server_default=sa.text("now()"), nullable=False,
        ),
        sa.CheckConstraint(
            "summary IS NULL OR char_length(summary) <= 2000",
            name=op.f("ck_appointment_visit_summary_length"),
        ),
        sa.CheckConstraint(
            "recommendations IS NULL OR "
            "char_length(recommendations) <= 2000",
            name=op.f("ck_appointment_visit_recommendations_length"),
        ),
        sa.CheckConstraint(
            "follow_up IS NULL OR char_length(follow_up) <= 500",
            name=op.f("ck_appointment_visit_follow_up_length"),
        ),
        sa.CheckConstraint(
            "audio IS NULL OR octet_length(audio) <= 5242880",
            name=op.f("ck_appointment_visit_audio_size"),
        ),
        sa.ForeignKeyConstraint(
            ["appointment_id"], ["appointment.id"],
            ondelete="CASCADE",
            name=op.f(
                "fk_appointment_visit_appointment_id_appointment"
            ),
        ),
        sa.ForeignKeyConstraint(
            ["updated_by_account_id"], ["account.id"],
            ondelete="SET NULL",
            name=op.f(
                "fk_appointment_visit_updated_by_account_id_account"
            ),
        ),
        sa.PrimaryKeyConstraint(
            "appointment_id", name=op.f("pk_appointment_visit")
        ),
    )


def downgrade() -> None:
    """Remove visit notes without changing appointments."""
    op.drop_table("appointment_visit")
