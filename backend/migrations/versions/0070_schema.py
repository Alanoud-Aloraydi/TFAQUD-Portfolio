"""The whole database, as migrations 0001 to 0070 left it, in one step.

This replaces those seventy migrations. A database made before it is
already at revision 0070, so this never runs there; on a new database it
makes every table, check, index, function and trigger at once, from
0070_schema.sql. Every later change is a migration of its own.

Revision ID: 0070
Revises: (none)
"""

from pathlib import Path

from alembic import op

revision = "0070"
down_revision = None
branch_labels = None
depends_on = None

SCHEMA = Path(__file__).with_name("0070_schema.sql")

TABLES = (
    "account", "account_photo", "account_session", "appointment",
    "appointment_companion", "appointment_visit", "care_circle",
    "care_circle_invitation", "care_circle_manager", "care_circle_photo",
    "care_circle_request", "emergency_contact", "measurement_plan",
    "measurement_plan_time", "measurement_plan_version",
    "measurement_plan_weekday", "measurement_reading", "measurement_target",
    "medication_dose_record", "medication_extra_dose", "medication_plan",
    "medication_plan_photo", "medication_plan_version",
    "medication_schedule", "medication_schedule_day",
    "medication_schedule_month_day", "notification_log", "otp_request",
    "otp_send", "patient_allergy", "patient_condition", "task_snooze",
)

FUNCTIONS = (
    "fn_assert_care_circle(uuid)", "fn_assert_medication_plan(uuid)",
    "fn_check_care_circle()", "fn_check_medication_dose()",
    "fn_check_medication_plan()", "fn_guard_account_care()",
    "fn_lock_care_circle()", "fn_lock_medication_circle()",
    "fn_measurement_conditions_unique(text[])",
)


def upgrade():
    op.execute(SCHEMA.read_text(encoding="utf-8"))


def downgrade():
    # The function on two tables' rows goes with them (CASCADE).
    op.execute(f"DROP TABLE {', '.join(TABLES)} CASCADE")
    op.execute(f"DROP FUNCTION {', '.join(FUNCTIONS)}")
