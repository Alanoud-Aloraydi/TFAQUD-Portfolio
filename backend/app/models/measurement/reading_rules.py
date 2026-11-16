"""The database rules of a measurement reading."""

from sqlalchemy import CheckConstraint, ForeignKeyConstraint, UniqueConstraint

from app.models.measurement.kinds import (
    CONDITIONS_CHECK,
    CONDITIONS_ONCE,
    KINDS_SQL,
    TARGET_BY_KIND,
)

READING_TABLE_ARGS = (
    # One outcome per reading time of a day.
    UniqueConstraint(
        "plan_version_id", "scheduled_on", "scheduled_time",
        name="uq_measurement_reading_plan_version_scheduled_on_"
        "scheduled_time",
    ),
    # A task's reading names one of its version's reading times.
    ForeignKeyConstraint(
        ["plan_version_id", "scheduled_time"],
        [
            "measurement_plan_time.plan_version_id",
            "measurement_plan_time.time_of_day",
        ],
        ondelete="CASCADE",
        name="fk_measurement_reading_plan_version_id_"
        "measurement_plan_time",
    ),
    CheckConstraint(KINDS_SQL, name="kind"),
    CheckConstraint("outcome IN ('read', 'skipped')", name="outcome"),
    CheckConstraint(CONDITIONS_CHECK, name="conditions"),
    CheckConstraint(CONDITIONS_ONCE, name="conditions_once"),
    CheckConstraint(
        "outcome = 'read' OR plan_version_id IS NOT NULL",
        name="skip_linked",
    ),
    CheckConstraint(
        "note IS NULL OR char_length(note) <= 250",
        name="note_length",
    ),
    CheckConstraint(
        "skip_reason_code IS NULL OR skip_reason_code IN "
        "('forgotten', 'equipment_unavailable', 'patient_refused', "
        "'unwell', 'other')",
        name="skip_reason",
    ),
    CheckConstraint(
        "skip_reason_note IS NULL OR "
        "(skip_reason_code = 'other' AND "
        "char_length(skip_reason_note) BETWEEN 1 AND 250)",
        name="skip_reason_note",
    ),
    CheckConstraint(
        "(outcome = 'read' AND skip_reason_code IS NULL AND "
        "skip_reason_note IS NULL) OR outcome = 'skipped'",
        name="skip_reason_outcome",
    ),
    # The words of «أخرى», only with it (migration 0028).
    CheckConstraint(
        "other_text IS NULL OR (char_length(other_text) "
        "BETWEEN 1 AND 60 AND 'other' = ANY(conditions))",
        name="other_text",
    ),
    CheckConstraint(
        "(plan_version_id IS NULL AND scheduled_on IS NULL "
        "AND scheduled_time IS NULL) OR "
        "(plan_version_id IS NOT NULL AND scheduled_on IS NOT NULL "
        "AND scheduled_time IS NOT NULL)",
        name="schedule_pair",
    ),
    CheckConstraint(
        "(outcome = 'skipped' AND measured_at IS NULL AND "
        "glucose_value IS NULL AND systolic_value IS NULL AND "
        "diastolic_value IS NULL AND followed_up_at IS NULL) OR "
        "(outcome = 'read' AND measured_at IS NOT NULL AND "
        "((kind = 'glucose' AND glucose_value BETWEEN 1 AND 999 "
        "AND systolic_value IS NULL AND diastolic_value IS NULL) OR "
        "(kind = 'blood_pressure' AND glucose_value IS NULL "
        "AND systolic_value BETWEEN 1 AND 999 "
        "AND diastolic_value BETWEEN 1 AND 999 "
        "AND systolic_value > diastolic_value)))",
        name="value_shape",
    ),
    CheckConstraint(
        "(glucose_low IS NULL AND glucose_high IS NULL AND "
        "systolic_limit IS NULL AND diastolic_limit IS NULL) OR "
        "(plan_version_id IS NULL AND outcome = 'read' AND ("
        + TARGET_BY_KIND + "))",
        name="free_target_shape",
    ),
)
