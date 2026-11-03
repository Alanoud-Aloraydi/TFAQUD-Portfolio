"""Add versioned measurement plans and explicit readings.

Revision ID: 0010
Revises: 0009
"""

from alembic import op
import sqlalchemy as sa

revision = "0010"
down_revision = "0009"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create plans, dated revisions, and recorded outcomes."""
    op.create_table(
        "measurement_plan",
        sa.Column(
            "id",
            sa.Uuid(),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column("kind", sa.Text(), nullable=False),
        sa.Column("created_by_account_id", sa.Uuid()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("stopped_at", sa.DateTime(timezone=True)),
        sa.CheckConstraint(
            "kind IN ('glucose', 'bp')", name=op.f("ck_measurement_plan_kind")
        ),
        sa.ForeignKeyConstraint(
            ["patient_id"],
            ["patient.id"],
            ondelete="CASCADE",
            name=op.f("fk_measurement_plan_patient_id_patient"),
        ),
        sa.ForeignKeyConstraint(
            ["created_by_account_id"],
            ["account.id"],
            ondelete="SET NULL",
            name=op.f("fk_measurement_plan_created_by_account_id_account"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_measurement_plan")),
    )
    op.create_index(
        op.f("ix_measurement_plan_patient_id"),
        "measurement_plan",
        ["patient_id"],
    )
    op.create_table(
        "measurement_plan_version",
        sa.Column(
            "id",
            sa.Uuid(),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("plan_id", sa.Uuid(), nullable=False),
        sa.Column("number", sa.Integer(), nullable=False),
        sa.Column("effective_from_on", sa.Date(), nullable=False),
        sa.Column("effective_until_on", sa.Date()),
        sa.Column("time_of_day", sa.Time(), nullable=False),
        sa.Column("weekdays_mask", sa.SmallInteger(), nullable=False),
        sa.Column("grace_minutes", sa.SmallInteger(), nullable=False),
        sa.Column("glucose_context", sa.Text()),
        sa.Column("glucose_low", sa.SmallInteger()),
        sa.Column("glucose_high", sa.SmallInteger()),
        sa.Column("systolic_limit", sa.SmallInteger()),
        sa.Column("diastolic_limit", sa.SmallInteger()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "number > 0", name=op.f("ck_measurement_plan_version_number")
        ),
        sa.CheckConstraint(
            "weekdays_mask BETWEEN 1 AND 127",
            name=op.f("ck_measurement_plan_version_weekdays"),
        ),
        sa.CheckConstraint(
            "grace_minutes IN (30, 60, 120)",
            name=op.f("ck_measurement_plan_version_grace_minutes"),
        ),
        sa.CheckConstraint(
            "effective_until_on IS NULL OR "
            "effective_until_on > effective_from_on",
            name=op.f("ck_measurement_plan_version_effective_period"),
        ),
        sa.CheckConstraint(
            "(glucose_low IS NOT NULL AND glucose_high IS NOT NULL "
            "AND glucose_low BETWEEN 1 AND 999 "
            "AND glucose_high BETWEEN 1 AND 999 "
            "AND glucose_high > glucose_low "
            "AND systolic_limit IS NULL AND diastolic_limit IS NULL) OR "
            "(glucose_low IS NULL AND glucose_high IS NULL "
            "AND glucose_context IS NULL "
            "AND systolic_limit BETWEEN 1 AND 999 "
            "AND diastolic_limit BETWEEN 1 AND 999 "
            "AND systolic_limit > diastolic_limit)",
            name=op.f("ck_measurement_plan_version_target_shape"),
        ),
        sa.CheckConstraint(
            "glucose_context IS NULL OR glucose_context IN "
            "('fasting', 'before_meal', 'after_meal', 'bedtime', 'other')",
            name=op.f("ck_measurement_plan_version_glucose_context"),
        ),
        sa.ForeignKeyConstraint(
            ["plan_id"],
            ["measurement_plan.id"],
            ondelete="CASCADE",
            name=op.f("fk_measurement_plan_version_plan_id_measurement_plan"),
        ),
        sa.PrimaryKeyConstraint(
            "id", name=op.f("pk_measurement_plan_version")
        ),
        sa.UniqueConstraint(
            "plan_id",
            "number",
            name=op.f("uq_measurement_plan_version_plan_id"),
        ),
        sa.UniqueConstraint(
            "plan_id",
            "effective_from_on",
            name="uq_measurement_plan_version_effective_from_on",
        ),
    )
    op.create_table(
        "measurement_record",
        sa.Column(
            "id",
            sa.Uuid(),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column("plan_version_id", sa.Uuid()),
        sa.Column("scheduled_on", sa.Date()),
        sa.Column("kind", sa.Text(), nullable=False),
        sa.Column("outcome", sa.Text(), nullable=False),
        sa.Column("measured_at", sa.DateTime(timezone=True)),
        sa.Column("value_one", sa.SmallInteger()),
        sa.Column("value_two", sa.SmallInteger()),
        sa.Column("glucose_context", sa.Text()),
        sa.Column("condition", sa.Text()),
        sa.Column("note", sa.Text()),
        sa.Column("followed_up_at", sa.DateTime(timezone=True)),
        sa.Column("recorded_by_account_id", sa.Uuid()),
        sa.Column(
            "recorded_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "kind IN ('glucose', 'bp')",
            name=op.f("ck_measurement_record_kind"),
        ),
        sa.CheckConstraint(
            "outcome IN ('read', 'skipped')",
            name=op.f("ck_measurement_record_outcome"),
        ),
        sa.CheckConstraint(
            "glucose_context IS NULL OR glucose_context IN "
            "('fasting', 'before_meal', 'after_meal', 'bedtime', 'other')",
            name=op.f("ck_measurement_record_glucose_context"),
        ),
        sa.CheckConstraint(
            "condition IS NULL OR condition IN "
            "('exertion', 'after_meal', 'stress', 'illness')",
            name=op.f("ck_measurement_record_condition"),
        ),
        sa.CheckConstraint(
            "kind = 'glucose' OR glucose_context IS NULL",
            name=op.f("ck_measurement_record_context_kind"),
        ),
        sa.CheckConstraint(
            "outcome = 'read' OR plan_version_id IS NOT NULL",
            name=op.f("ck_measurement_record_skip_linked"),
        ),
        sa.CheckConstraint(
            "note IS NULL OR char_length(note) <= 250",
            name=op.f("ck_measurement_record_note_length"),
        ),
        sa.CheckConstraint(
            "(plan_version_id IS NULL AND scheduled_on IS NULL) OR "
            "(plan_version_id IS NOT NULL AND scheduled_on IS NOT NULL)",
            name=op.f("ck_measurement_record_schedule_pair"),
        ),
        sa.CheckConstraint(
            "(outcome = 'skipped' AND measured_at IS NULL AND "
            "value_one IS NULL AND value_two IS NULL AND "
            "followed_up_at IS NULL) OR "
            "(outcome = 'read' AND measured_at IS NOT NULL AND "
            "value_one BETWEEN 1 AND 999 AND "
            "((kind = 'glucose' AND value_two IS NULL) OR "
            "(kind = 'bp' AND value_two BETWEEN 1 AND 999 "
            "AND value_one > value_two)))",
            name=op.f("ck_measurement_record_value_shape"),
        ),
        sa.ForeignKeyConstraint(
            ["patient_id"],
            ["patient.id"],
            ondelete="CASCADE",
            name=op.f("fk_measurement_record_patient_id_patient"),
        ),
        sa.ForeignKeyConstraint(
            ["plan_version_id"],
            ["measurement_plan_version.id"],
            ondelete="CASCADE",
            name=op.f(
                "fk_measurement_record_plan_version_id_"
                "measurement_plan_version"
            ),
        ),
        sa.ForeignKeyConstraint(
            ["recorded_by_account_id"],
            ["account.id"],
            ondelete="SET NULL",
            name=op.f("fk_measurement_record_recorded_by_account_id_account"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_measurement_record")),
        sa.UniqueConstraint(
            "plan_version_id",
            "scheduled_on",
            name=op.f("uq_measurement_record_plan_version_id"),
        ),
    )
    op.create_index(
        op.f("ix_measurement_record_patient_id"),
        "measurement_record",
        ["patient_id"],
    )


def downgrade() -> None:
    """Remove measurement data in an isolated migration test database."""
    op.drop_index(
        op.f("ix_measurement_record_patient_id"),
        table_name="measurement_record",
    )
    op.drop_table("measurement_record")
    op.drop_table("measurement_plan_version")
    op.drop_index(
        op.f("ix_measurement_plan_patient_id"), table_name="measurement_plan"
    )
    op.drop_table("measurement_plan")
