"""Separate planned measurement state and persist measurement skip reasons.

Revision ID: 0045
Revises: 0044
"""
from alembic import op
import sqlalchemy as sa

revision = "0045"
down_revision = "0044"
branch_labels = None
depends_on = None

_TIME = "measurement_plan_time"
_READING = "measurement_reading"


def upgrade() -> None:
    op.add_column(_TIME, sa.Column("measurement_state", sa.Text()))
    op.execute(
        f"UPDATE {_TIME} SET measurement_state = (SELECT value FROM "
        "unnest(conditions) value WHERE value IN "
        "('fasting', 'before_meal', 'after_meal') LIMIT 1)"
    )
    op.create_check_constraint(
        op.f("ck_measurement_plan_time_measurement_state"), _TIME,
        "measurement_state IS NULL OR measurement_state IN "
        "('fasting', 'before_meal', 'after_meal')",
    )
    op.drop_constraint(
        op.f("ck_measurement_plan_time_conditions_once"), _TIME,
        type_="check",
    )
    op.drop_constraint(
        op.f("ck_measurement_plan_time_conditions"), _TIME, type_="check"
    )
    op.drop_column(_TIME, "conditions")

    op.add_column(_READING, sa.Column("skip_reason_code", sa.Text()))
    op.add_column(_READING, sa.Column("skip_reason_note", sa.Text()))
    op.create_check_constraint(
        op.f("ck_measurement_reading_skip_reason"), _READING,
        "skip_reason_code IS NULL OR skip_reason_code IN "
        "('forgotten', 'equipment_unavailable', 'patient_refused', "
        "'unwell', 'other')",
    )
    op.create_check_constraint(
        op.f("ck_measurement_reading_skip_reason_note"), _READING,
        "skip_reason_note IS NULL OR (skip_reason_code = 'other' AND "
        "char_length(skip_reason_note) BETWEEN 1 AND 250)",
    )
    op.create_check_constraint(
        op.f("ck_measurement_reading_skip_reason_outcome"), _READING,
        "(outcome = 'read' AND skip_reason_code IS NULL AND "
        "skip_reason_note IS NULL) OR outcome = 'skipped'",
    )


def downgrade() -> None:
    for name in (
        "skip_reason_outcome", "skip_reason_note", "skip_reason",
    ):
        op.drop_constraint(
            op.f(f"ck_measurement_reading_{name}"), _READING, type_="check"
        )
    op.drop_column(_READING, "skip_reason_note")
    op.drop_column(_READING, "skip_reason_code")

    op.add_column(
        _TIME,
        sa.Column(
            "conditions", sa.ARRAY(sa.Text()), nullable=False,
            server_default=sa.text("'{}'"),
        ),
    )
    op.execute(
        f"UPDATE {_TIME} SET conditions = CASE WHEN measurement_state IS "
        "NULL THEN ARRAY[]::text[] ELSE ARRAY[measurement_state] END"
    )
    op.create_check_constraint(
        op.f("ck_measurement_plan_time_conditions"), _TIME,
        "conditions <@ ARRAY['fasting', 'before_meal', 'after_meal', "
        "'bedtime', 'exertion', 'stress', 'illness', 'other']::text[]",
    )
    op.create_check_constraint(
        op.f("ck_measurement_plan_time_conditions_once"), _TIME,
        "fn_measurement_conditions_unique(conditions)",
    )
    op.drop_constraint(
        op.f("ck_measurement_plan_time_measurement_state"), _TIME,
        type_="check",
    )
    op.drop_column(_TIME, "measurement_state")
