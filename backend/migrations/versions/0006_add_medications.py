"""Add versioned medication plans and explicit dose records."""

from pathlib import Path

from alembic import op
import sqlalchemy as sa

revision = "0006"
down_revision = "0005"
branch_labels = None
depends_on = None


def _create_plan_tables():
    """Create stable plans and their immutable versions."""
    op.create_table(
        "medication_plan",
        sa.Column(
            "id",
            sa.Uuid(),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column("created_by_account_id", sa.Uuid()),
        sa.Column("current_normalized_name", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("discontinued_at", sa.DateTime(timezone=True)),
        sa.Column("discontinued_by_account_id", sa.Uuid()),
        sa.CheckConstraint(
            "length(btrim(current_normalized_name)) > 0",
            name=op.f("ck_medication_plan_normalized_name_nonblank"),
        ),
        sa.CheckConstraint(
            "discontinued_at IS NOT NULL "
            "OR discontinued_by_account_id IS NULL",
            name=op.f("ck_medication_plan_discontinuation_state"),
        ),
        sa.ForeignKeyConstraint(
            ["patient_id"],
            ["patient.id"],
            ondelete="CASCADE",
            name=op.f("fk_medication_plan_patient_id_patient"),
        ),
        sa.ForeignKeyConstraint(
            ["created_by_account_id"],
            ["account.id"],
            ondelete="SET NULL",
            name=op.f(
                "fk_medication_plan_created_by_account_id_account"
            ),
        ),
        sa.ForeignKeyConstraint(
            ["discontinued_by_account_id"],
            ["account.id"],
            ondelete="SET NULL",
            name=op.f(
                "fk_medication_plan_discontinued_by_account_id_account"
            ),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_medication_plan")),
    )
    op.create_index(
        "ix_medication_plan_patient_name",
        "medication_plan",
        ["patient_id", "current_normalized_name"],
    )
    op.create_index(
        op.f("ix_medication_plan_created_by_account_id"),
        "medication_plan",
        ["created_by_account_id"],
    )
    op.create_index(
        op.f("ix_medication_plan_discontinued_by_account_id"),
        "medication_plan",
        ["discontinued_by_account_id"],
    )

    op.create_table(
        "medication_plan_version",
        sa.Column(
            "id",
            sa.Uuid(),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("medication_plan_id", sa.Uuid(), nullable=False),
        sa.Column("version_number", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=50), nullable=False),
        sa.Column("normalized_name", sa.Text(), nullable=False),
        sa.Column("strength_text", sa.String(length=50)),
        sa.Column("dosage_form", sa.Text(), nullable=False),
        sa.Column("reason_for_use", sa.String(length=100)),
        sa.Column("instructions", sa.String(length=250)),
        sa.Column("treatment_starts_on", sa.Date(), nullable=False),
        sa.Column("treatment_ends_on", sa.Date()),
        sa.Column(
            "effective_from", sa.DateTime(timezone=True), nullable=False
        ),
        sa.Column("effective_until", sa.DateTime(timezone=True)),
        sa.Column("created_by_account_id", sa.Uuid()),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "version_number >= 1",
            name=op.f("ck_medication_plan_version_version_number"),
        ),
        sa.CheckConstraint(
            "length(btrim(name)) > 0",
            name=op.f("ck_medication_plan_version_name_nonblank"),
        ),
        sa.CheckConstraint(
            "length(btrim(normalized_name)) > 0",
            name=op.f(
                "ck_medication_plan_version_normalized_name_nonblank"
            ),
        ),
        sa.CheckConstraint(
            "dosage_form IN ('tablet', 'capsule', 'liquid', "
            "'drops', 'inhaler', 'injection')",
            name=op.f("ck_medication_plan_version_dosage_form"),
        ),
        sa.CheckConstraint(
            "treatment_ends_on IS NULL "
            "OR treatment_ends_on >= treatment_starts_on",
            name=op.f("ck_medication_plan_version_treatment_dates"),
        ),
        sa.CheckConstraint(
            "effective_until IS NULL "
            "OR effective_until >= effective_from",
            name=op.f("ck_medication_plan_version_effective_period"),
        ),
        sa.ForeignKeyConstraint(
            ["medication_plan_id"],
            ["medication_plan.id"],
            ondelete="CASCADE",
            name=op.f(
                "fk_medication_plan_version_medication_plan_id_"
                "medication_plan"
            ),
        ),
        sa.ForeignKeyConstraint(
            ["created_by_account_id"],
            ["account.id"],
            ondelete="SET NULL",
            name=op.f(
                "fk_medication_plan_version_created_by_account_id_account"
            ),
        ),
        sa.PrimaryKeyConstraint(
            "id", name=op.f("pk_medication_plan_version")
        ),
        sa.UniqueConstraint(
            "medication_plan_id",
            "version_number",
            name=op.f("uq_medication_plan_version_medication_plan_id"),
        ),
    )
    op.create_index(
        "uq_medication_plan_version_current",
        "medication_plan_version",
        ["medication_plan_id"],
        unique=True,
        postgresql_where=sa.text("effective_until IS NULL"),
    )
    op.create_index(
        op.f("ix_medication_plan_version_created_by_account_id"),
        "medication_plan_version",
        ["created_by_account_id"],
    )


def _create_schedule_tables():
    """Create dose schedules and normalized weekday rows."""
    op.create_table(
        "medication_schedule",
        sa.Column(
            "id",
            sa.Uuid(),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("plan_version_id", sa.Uuid(), nullable=False),
        sa.Column("time_of_day", sa.Time(), nullable=False),
        sa.Column("dose_value", sa.Numeric(10, 3), nullable=False),
        sa.Column("dose_unit", sa.Text(), nullable=False),
        sa.Column("instructions", sa.String(length=250)),
        sa.CheckConstraint(
            "dose_value > 0",
            name=op.f("ck_medication_schedule_positive_dose"),
        ),
        sa.CheckConstraint(
            "dose_unit IN "
            "('tablet', 'capsule', 'mL', 'drop', 'puff', 'unit')",
            name=op.f("ck_medication_schedule_dose_unit"),
        ),
        sa.ForeignKeyConstraint(
            ["plan_version_id"],
            ["medication_plan_version.id"],
            ondelete="CASCADE",
            name=op.f(
                "fk_medication_schedule_plan_version_id_"
                "medication_plan_version"
            ),
        ),
        sa.PrimaryKeyConstraint(
            "id", name=op.f("pk_medication_schedule")
        ),
    )
    op.create_index(
        op.f("ix_medication_schedule_plan_version_id"),
        "medication_schedule",
        ["plan_version_id"],
    )

    op.create_table(
        "medication_schedule_day",
        sa.Column("schedule_id", sa.Uuid(), nullable=False),
        sa.Column("weekday", sa.SmallInteger(), nullable=False),
        sa.CheckConstraint(
            "weekday BETWEEN 1 AND 7",
            name=op.f("ck_medication_schedule_day_weekday"),
        ),
        sa.ForeignKeyConstraint(
            ["schedule_id"],
            ["medication_schedule.id"],
            ondelete="CASCADE",
            name=op.f(
                "fk_medication_schedule_day_schedule_id_"
                "medication_schedule"
            ),
        ),
        sa.PrimaryKeyConstraint(
            "schedule_id",
            "weekday",
            name=op.f("pk_medication_schedule_day"),
        ),
    )


def _create_dose_records():
    """Create explicit outcomes without pre-generating pending doses."""
    op.create_table(
        "medication_dose_record",
        sa.Column(
            "id",
            sa.Uuid(),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("schedule_id", sa.Uuid(), nullable=False),
        sa.Column("scheduled_on", sa.Date(), nullable=False),
        sa.Column("outcome", sa.Text(), nullable=False),
        sa.Column("taken_at", sa.DateTime(timezone=True)),
        sa.Column("skip_reason_code", sa.String(length=40)),
        sa.Column("skip_reason_note", sa.String(length=250)),
        sa.Column("recorded_by_account_id", sa.Uuid()),
        sa.Column(
            "recorded_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "outcome IN ('taken', 'skipped')",
            name=op.f("ck_medication_dose_record_outcome"),
        ),
        sa.CheckConstraint(
            "(outcome = 'taken' AND taken_at IS NOT NULL "
            "AND skip_reason_code IS NULL AND skip_reason_note IS NULL) "
            "OR (outcome = 'skipped' AND taken_at IS NULL)",
            name=op.f("ck_medication_dose_record_outcome_details"),
        ),
        sa.CheckConstraint(
            "taken_at IS NULL OR taken_at <= recorded_at",
            name=op.f("ck_medication_dose_record_taken_before_recorded"),
        ),
        sa.ForeignKeyConstraint(
            ["schedule_id"],
            ["medication_schedule.id"],
            ondelete="CASCADE",
            name=op.f(
                "fk_medication_dose_record_schedule_id_"
                "medication_schedule"
            ),
        ),
        sa.ForeignKeyConstraint(
            ["recorded_by_account_id"],
            ["account.id"],
            ondelete="SET NULL",
            name=op.f(
                "fk_medication_dose_record_recorded_by_account_id_account"
            ),
        ),
        sa.PrimaryKeyConstraint(
            "id", name=op.f("pk_medication_dose_record")
        ),
        sa.UniqueConstraint(
            "schedule_id",
            "scheduled_on",
            name=op.f("uq_medication_dose_record_schedule_id"),
        ),
    )
    op.create_index(
        "ix_medication_dose_record_recorded_by_account_id",
        "medication_dose_record",
        ["recorded_by_account_id"],
    )


def upgrade():
    """Install medication persistence and transaction-wide rules."""
    _create_plan_tables()
    _create_schedule_tables()
    _create_dose_records()
    rules = Path(__file__).with_name("0006_medication_rules.sql")
    op.execute(rules.read_text(encoding="utf-8"))


def downgrade():
    """Remove medication rules and tables without touching care data."""
    op.execute("DROP FUNCTION check_medication_dose() CASCADE")
    op.execute("DROP FUNCTION check_medication_plan() CASCADE")
    op.execute("DROP FUNCTION assert_medication_plan(uuid)")
    op.execute("DROP FUNCTION lock_medication_patient() CASCADE")
    op.drop_table("medication_dose_record")
    op.drop_table("medication_schedule_day")
    op.drop_table("medication_schedule")
    op.drop_table("medication_plan_version")
    op.drop_table("medication_plan")
