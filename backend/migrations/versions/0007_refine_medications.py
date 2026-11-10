"""Refine medication strength, revisions, and dose outcomes."""

from pathlib import Path

from alembic import op
import sqlalchemy as sa

revision = "0007"
down_revision = "0006"
branch_labels = None
depends_on = None


def _drop_rules():
    """Remove triggers before changing their referenced schema."""
    op.execute("DROP FUNCTION check_medication_dose() CASCADE")
    op.execute("DROP FUNCTION check_medication_plan() CASCADE")
    op.execute("DROP FUNCTION assert_medication_plan(uuid)")
    op.execute(
        "DROP FUNCTION IF EXISTS medication_treatment_period("
        "medication_plan, medication_plan_version)"
    )
    op.execute("DROP FUNCTION lock_medication_patient() CASCADE")


def _add_structured_strength():
    """Convert parseable legacy strength text into structured values."""
    op.add_column(
        "medication_plan_version",
        sa.Column("strength_value", sa.Numeric(10, 3)),
    )
    op.add_column(
        "medication_plan_version",
        sa.Column("strength_unit", sa.Text()),
    )
    op.execute(
        """
        UPDATE medication_plan_version
        SET strength_value = substring(
                strength_text FROM '^\\s*([0-9]+(?:\\.[0-9]+)?)'
            )::numeric,
            strength_unit = substring(
                strength_text FROM
                '(mg/5mL|mg/mL|mcg/dose|unit/mL|mcg|mg|%)\\s*$'
            )
        WHERE strength_text ~
            '^\\s*[0-9]+(?:\\.[0-9]+)?\\s*'
            '(mg/5mL|mg/mL|mcg/dose|unit/mL|mcg|mg|%)\\s*$'
        """
    )
    op.execute(
        """
        DO $$
        BEGIN
            IF EXISTS (
                SELECT 1 FROM medication_plan_version
                WHERE strength_value IS NULL OR strength_unit IS NULL
            ) THEN
                RAISE EXCEPTION
                    'Medication strengths must be converted before migration';
            END IF;
        END
        $$
        """
    )
    op.alter_column(
        "medication_plan_version", "strength_value", nullable=False
    )
    op.alter_column(
        "medication_plan_version", "strength_unit", nullable=False
    )
    op.create_check_constraint(
        op.f("ck_medication_plan_version_positive_strength"),
        "medication_plan_version",
        "strength_value > 0",
    )
    op.create_check_constraint(
        op.f("ck_medication_plan_version_strength_unit"),
        "medication_plan_version",
        "strength_unit IN ('mg', 'mcg', 'mg/mL', 'mg/5mL', "
        "'mcg/dose', 'unit/mL', '%')",
    )
    op.drop_column("medication_plan_version", "strength_text")


def _replace_revision_period():
    """Represent revisions as inclusive-exclusive calendar dates."""
    op.add_column(
        "medication_plan_version",
        sa.Column("effective_from_on", sa.Date()),
    )
    op.add_column(
        "medication_plan_version",
        sa.Column("effective_until_on", sa.Date()),
    )
    op.execute(
        """
        UPDATE medication_plan_version
        SET effective_from_on =
                (effective_from AT TIME ZONE 'Asia/Riyadh')::date,
            effective_until_on = CASE
                WHEN effective_until IS NULL THEN NULL
                ELSE (effective_until AT TIME ZONE 'Asia/Riyadh')::date
            END
        """
    )
    op.alter_column(
        "medication_plan_version", "effective_from_on", nullable=False
    )
    op.drop_index(
        "uq_medication_plan_version_current",
        table_name="medication_plan_version",
    )
    op.drop_constraint(
        op.f("ck_medication_plan_version_effective_period"),
        "medication_plan_version",
        type_="check",
    )
    op.create_check_constraint(
        op.f("ck_medication_plan_version_effective_period"),
        "medication_plan_version",
        "effective_until_on IS NULL "
        "OR effective_until_on > effective_from_on",
    )
    op.create_check_constraint(
        op.f("ck_medication_plan_version_effective_treatment"),
        "medication_plan_version",
        "treatment_ends_on IS NULL "
        "OR treatment_ends_on >= effective_from_on",
    )
    op.create_unique_constraint(
        op.f("uq_medication_plan_version_effective_from_on"),
        "medication_plan_version",
        ["medication_plan_id", "effective_from_on"],
    )
    op.create_index(
        "uq_medication_plan_version_open",
        "medication_plan_version",
        ["medication_plan_id"],
        unique=True,
        postgresql_where=sa.text("effective_until_on IS NULL"),
    )
    op.drop_column("medication_plan_version", "effective_until")
    op.drop_column("medication_plan_version", "effective_from")


def _remove_duplicated_plan_name():
    """Keep normalized names only on the version that owns the value."""
    op.drop_index(
        "ix_medication_plan_patient_name", table_name="medication_plan"
    )
    op.drop_constraint(
        op.f("ck_medication_plan_normalized_name_nonblank"),
        "medication_plan",
        type_="check",
    )
    op.drop_column("medication_plan", "current_normalized_name")


def _constrain_skip_reasons():
    """Restrict optional skip reasons to the approved vocabulary."""
    op.create_check_constraint(
        op.f("ck_medication_dose_record_skip_reason"),
        "medication_dose_record",
        "skip_reason_code IS NULL OR skip_reason_code IN "
        "('forgotten', 'unavailable', 'side_effects', "
        "'patient_refused', 'other')",
    )
    op.create_check_constraint(
        op.f("ck_medication_dose_record_skip_note"),
        "medication_dose_record",
        "skip_reason_note IS NULL OR skip_reason_code = 'other'",
    )


def upgrade():
    """Apply the approved medication schema refinements."""
    _drop_rules()
    _add_structured_strength()
    _replace_revision_period()
    _remove_duplicated_plan_name()
    _constrain_skip_reasons()
    rules = Path(__file__).with_name("0007_medication_rules.sql")
    op.execute(rules.read_text(encoding="utf-8"))


def downgrade():
    """Restore the original medication schema without deleting records."""
    _drop_rules()
    op.drop_constraint(
        op.f("ck_medication_dose_record_skip_note"),
        "medication_dose_record",
        type_="check",
    )
    op.drop_constraint(
        op.f("ck_medication_dose_record_skip_reason"),
        "medication_dose_record",
        type_="check",
    )
    op.add_column(
        "medication_plan",
        sa.Column("current_normalized_name", sa.Text()),
    )
    op.execute(
        """
        UPDATE medication_plan p
        SET current_normalized_name = v.normalized_name
        FROM medication_plan_version v
        WHERE v.medication_plan_id = p.id
          AND v.effective_until_on IS NULL
        """
    )
    op.alter_column(
        "medication_plan", "current_normalized_name", nullable=False
    )
    op.create_check_constraint(
        op.f("ck_medication_plan_normalized_name_nonblank"),
        "medication_plan",
        "length(btrim(current_normalized_name)) > 0",
    )
    op.create_index(
        "ix_medication_plan_patient_name",
        "medication_plan",
        ["patient_id", "current_normalized_name"],
    )
    op.add_column(
        "medication_plan_version",
        sa.Column("effective_from", sa.DateTime(timezone=True)),
    )
    op.add_column(
        "medication_plan_version",
        sa.Column("effective_until", sa.DateTime(timezone=True)),
    )
    op.execute(
        """
        UPDATE medication_plan_version
        SET effective_from = effective_from_on::timestamp
                AT TIME ZONE 'Asia/Riyadh',
            effective_until = CASE
                WHEN effective_until_on IS NULL THEN NULL
                ELSE effective_until_on::timestamp
                    AT TIME ZONE 'Asia/Riyadh'
            END
        """
    )
    op.alter_column(
        "medication_plan_version", "effective_from", nullable=False
    )
    op.drop_index(
        "uq_medication_plan_version_open",
        table_name="medication_plan_version",
    )
    op.drop_constraint(
        op.f("uq_medication_plan_version_effective_from_on"),
        "medication_plan_version",
        type_="unique",
    )
    op.drop_constraint(
        op.f("ck_medication_plan_version_effective_period"),
        "medication_plan_version",
        type_="check",
    )
    op.execute(
        "ALTER TABLE medication_plan_version DROP CONSTRAINT IF EXISTS "
        "ck_medication_plan_version_effective_treatment"
    )
    op.create_check_constraint(
        op.f("ck_medication_plan_version_effective_period"),
        "medication_plan_version",
        "effective_until IS NULL OR effective_until >= effective_from",
    )
    op.create_index(
        "uq_medication_plan_version_current",
        "medication_plan_version",
        ["medication_plan_id"],
        unique=True,
        postgresql_where=sa.text("effective_until IS NULL"),
    )
    op.drop_column("medication_plan_version", "effective_until_on")
    op.drop_column("medication_plan_version", "effective_from_on")
    op.add_column(
        "medication_plan_version",
        sa.Column("strength_text", sa.String(length=50)),
    )
    op.execute(
        """
        UPDATE medication_plan_version
        SET strength_text = strength_value::text || ' ' || strength_unit
        """
    )
    op.drop_constraint(
        op.f("ck_medication_plan_version_strength_unit"),
        "medication_plan_version",
        type_="check",
    )
    op.drop_constraint(
        op.f("ck_medication_plan_version_positive_strength"),
        "medication_plan_version",
        type_="check",
    )
    op.drop_column("medication_plan_version", "strength_unit")
    op.drop_column("medication_plan_version", "strength_value")
    rules = Path(__file__).with_name("0006_medication_rules.sql")
    op.execute(rules.read_text(encoding="utf-8"))
