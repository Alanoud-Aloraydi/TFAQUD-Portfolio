"""The database rules of a medication plan version."""

from sqlalchemy import CheckConstraint, Index, UniqueConstraint, text

from app.plan_limits import MISSED_AFTER_CHECK

VERSION_TABLE_ARGS = (
    CheckConstraint("version_number >= 1", name="version_number"),
    CheckConstraint(
        "length(btrim(name)) BETWEEN 1 AND 50", name="name"
    ),
    CheckConstraint(
        "length(btrim(normalized_name)) > 0",
        name="normalized_name_nonblank",
    ),
    CheckConstraint(
        "dosage_form IN "
        "('tablet', 'capsule', 'liquid', 'drops', "
        "'inhaler', 'nebulizer', 'injection')",
        name="dosage_form",
    ),
    CheckConstraint(
        "treatment_ends_on IS NULL "
        "OR treatment_ends_on >= treatment_starts_on",
        name="treatment_dates",
    ),
    CheckConstraint(
        "effective_until_on IS NULL "
        "OR effective_until_on > effective_from_on",
        name="effective_period",
    ),
    CheckConstraint(
        "treatment_ends_on IS NULL "
        "OR treatment_ends_on >= effective_from_on",
        name="effective_treatment",
    ),
    CheckConstraint("strength_value > 0", name="positive_strength"),
    CheckConstraint(
        MISSED_AFTER_CHECK,
        name="missed_after_minutes",
    ),
    CheckConstraint(
        "strength_unit IN ('mg', 'mcg', 'mg/mL', 'mg/5mL', "
        "'mcg/dose', 'unit/mL', '%')",
        name="strength_unit",
    ),
    CheckConstraint(
        "reason_for_use IS NULL OR char_length(reason_for_use) <= 100",
        name="reason_for_use_length",
    ),
    CheckConstraint(
        "instructions IS NULL OR char_length(instructions) <= 250",
        name="instructions_length",
    ),
    UniqueConstraint(
        "medication_plan_id", "version_number",
        name="uq_medication_plan_version_medication_plan_id_"
        "version_number",
    ),
    Index(
        "uq_medication_plan_version_medication_plan_id_effective_from_on",
        "medication_plan_id",
        "effective_from_on",
        unique=True,
        postgresql_where=text("cancelled_at IS NULL"),
    ),
    Index(
        "uq_medication_plan_version_medication_plan_id_open",
        "medication_plan_id",
        unique=True,
        postgresql_where=text(
            "effective_until_on IS NULL AND cancelled_at IS NULL"
        ),
    ),
)
