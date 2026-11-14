"""«حالة القياس» for blood pressure: before or after the medicine, or the
morning.

Glucose keeps its three stomach states; pressure reading times, which had
none, now name one of three of their own, and a reading can carry the same
three among its «ظروف القياس».

Revision ID: 0052
Revises: 0051
"""
from alembic import op

revision = "0052"
down_revision = "0051"
branch_labels = None
depends_on = None

_GLUCOSE = "'fasting', 'before_meal', 'after_meal'"
_PRESSURE = "'before_medicine', 'after_medicine', 'morning'"
_OLD_CONDITIONS = (
    "'fasting', 'before_meal', 'after_meal', 'bedtime', "
    "'exertion', 'stress', 'illness', 'other'"
)
_NEW_CONDITIONS = (
    "'fasting', 'before_meal', 'after_meal', 'bedtime', "
    f"{_PRESSURE}, 'exertion', 'stress', 'illness', 'other'"
)


def _conditions(codes: str) -> None:
    # Only a reading carries «ظروف القياس»: 0045 took the column off the
    # plan's reading times and left them the one measurement_state.
    name = op.f("ck_measurement_reading_conditions")
    op.drop_constraint(name, "measurement_reading", type_="check")
    op.create_check_constraint(
        name, "measurement_reading", f"conditions <@ ARRAY[{codes}]::text[]"
    )


def _state(codes: str) -> None:
    name = op.f("ck_measurement_plan_time_measurement_state")
    op.drop_constraint(name, "measurement_plan_time", type_="check")
    op.create_check_constraint(
        name, "measurement_plan_time",
        f"measurement_state IS NULL OR measurement_state IN ({codes})",
    )


def upgrade() -> None:
    _conditions(_NEW_CONDITIONS)
    _state(f"{_GLUCOSE}, {_PRESSURE}")
    # Every pressure time had no state; «في الصباح» before 12:00, and
    # «بعد الدواء» after it, so no plan opens without one.
    op.execute(
        "UPDATE measurement_plan_time AS t SET measurement_state = "
        "CASE WHEN t.time_of_day < TIME '12:00' THEN 'morning' "
        "ELSE 'after_medicine' END "
        "FROM measurement_plan_version AS v "
        "JOIN measurement_plan AS p ON p.id = v.measurement_plan_id "
        "WHERE v.id = t.plan_version_id "
        "AND p.kind = 'blood_pressure' "
        "AND t.measurement_state IS NULL"
    )


def downgrade() -> None:
    """Take the new states off: pressure times keep none again."""
    op.execute(
        "UPDATE measurement_plan_time SET measurement_state = NULL "
        f"WHERE measurement_state IN ({_PRESSURE})"
    )
    op.execute(
        "UPDATE measurement_reading SET conditions = "
        f"array_remove(array_remove(array_remove(conditions, 'morning'), "
        "'before_medicine'), 'after_medicine')"
    )
    _state(_GLUCOSE)
    _conditions(_OLD_CONDITIONS)
