"""Add planned appointments and explicit outcomes.

Revision ID: 0011
Revises: 0010
"""

from alembic import op
import sqlalchemy as sa

revision = "0011"
down_revision = "0010"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create circle-patient appointments with constrained location data."""
    op.create_table(
        "appointment",
        sa.Column(
            "id", sa.Uuid(), server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column("specialty", sa.Text(), nullable=False),
        sa.Column("kind", sa.Text(), nullable=False),
        sa.Column("scheduled_on", sa.Date(), nullable=False),
        sa.Column("time_of_day", sa.Time(), nullable=False),
        sa.Column("place", sa.Text()),
        sa.Column("remote_method", sa.Text()),
        sa.Column("companion_account_id", sa.Uuid(), nullable=False),
        sa.Column("status", sa.Text(), nullable=False),
        sa.Column("created_by_account_id", sa.Uuid()),
        sa.Column(
            "created_at", sa.DateTime(timezone=True),
            server_default=sa.text("now()"), nullable=False,
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True),
            server_default=sa.text("now()"), nullable=False,
        ),
        sa.CheckConstraint(
            "kind IN ('follow_up', 'test', 'imaging', 'remote')",
            name=op.f("ck_appointment_kind"),
        ),
        sa.CheckConstraint(
            "status IN ('scheduled', 'completed', 'cancelled')",
            name=op.f("ck_appointment_status"),
        ),
        sa.CheckConstraint(
            "(kind = 'remote' AND remote_method IS NOT NULL "
            "AND remote_method IN ('video', 'phone') "
            "AND place IS NULL) OR (kind <> 'remote' AND "
            "remote_method IS NULL AND place IS NOT NULL AND "
            "length(btrim(place)) > 0)",
            name=op.f("ck_appointment_location_shape"),
        ),
        sa.CheckConstraint(
            "length(btrim(specialty)) > 0 AND "
            "char_length(specialty) <= 80",
            name=op.f("ck_appointment_specialty"),
        ),
        sa.CheckConstraint(
            "place IS NULL OR char_length(place) <= 160",
            name=op.f("ck_appointment_place_length"),
        ),
        sa.ForeignKeyConstraint(
            ["patient_id"], ["patient.id"], ondelete="CASCADE",
            name=op.f("fk_appointment_patient_id_patient"),
        ),
        sa.ForeignKeyConstraint(
            ["companion_account_id"], ["account.id"], ondelete="RESTRICT",
            name=op.f("fk_appointment_companion_account_id_account"),
        ),
        sa.ForeignKeyConstraint(
            ["created_by_account_id"], ["account.id"],
            ondelete="SET NULL",
            name=op.f("fk_appointment_created_by_account_id_account"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_appointment")),
    )
    op.create_index(
        op.f("ix_appointment_patient_id"), "appointment", ["patient_id"]
    )
    op.create_index(
        "ix_appointment_patient_schedule", "appointment",
        ["patient_id", "scheduled_on", "time_of_day"],
    )


def downgrade() -> None:
    """Remove appointments without touching earlier features."""
    op.drop_index("ix_appointment_patient_schedule", table_name="appointment")
    op.drop_index(op.f("ix_appointment_patient_id"), table_name="appointment")
    op.drop_table("appointment")
