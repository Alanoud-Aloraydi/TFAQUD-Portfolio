"""Judge readings by fixed normal ranges; a plan version needs no target.

Readings are judged by the fixed ranges of `app/measurements/ranges.py`
(by meal state and the patient's conditions), so a new plan version stores
no target. Old versions keep theirs; nothing reads them any more.

Revision ID: 0049
Revises: 0048
"""
from alembic import op

revision = "0049"
down_revision = "0048"
branch_labels = None
depends_on = None

_TABLE = "measurement_plan_version"
_SHAPE = (
    "(glucose_low IS NOT NULL AND glucose_high IS NOT NULL "
    "AND glucose_low BETWEEN 1 AND 999 "
    "AND glucose_high BETWEEN 1 AND 999 "
    "AND glucose_high > glucose_low "
    "AND systolic_limit IS NULL AND diastolic_limit IS NULL) OR "
    "(glucose_low IS NULL AND glucose_high IS NULL "
    "AND systolic_limit BETWEEN 1 AND 999 "
    "AND diastolic_limit BETWEEN 1 AND 999 "
    "AND systolic_limit > diastolic_limit)"
)
_NONE = (
    "glucose_low IS NULL AND glucose_high IS NULL "
    "AND systolic_limit IS NULL AND diastolic_limit IS NULL"
)


def _replace(condition: str) -> None:
    # `op.f` keeps the name as it is (see 0047).
    name = op.f(f"ck_{_TABLE}_target_shape")
    op.drop_constraint(name, _TABLE, type_="check")
    op.create_check_constraint(name, _TABLE, condition)


def upgrade() -> None:
    _replace(f"({_NONE}) OR {_SHAPE}")


def downgrade() -> None:
    """Give the versions without a target the general ranges' tops, as the
    old app suggested them: glucose 70–140, blood pressure 140/90."""
    op.execute(
        f"UPDATE {_TABLE} AS version SET glucose_low = 70, "
        "glucose_high = 140 FROM measurement_plan AS plan "
        "WHERE plan.id = version.measurement_plan_id "
        "AND plan.kind = 'glucose' AND version.glucose_low IS NULL"
    )
    op.execute(
        f"UPDATE {_TABLE} AS version SET systolic_limit = 140, "
        "diastolic_limit = 90 FROM measurement_plan AS plan "
        "WHERE plan.id = version.measurement_plan_id "
        "AND plan.kind = 'blood_pressure' "
        "AND version.systolic_limit IS NULL"
    )
    # PostgreSQL alters no table with deferred checks pending (see 0048).
    op.execute("SET CONSTRAINTS ALL IMMEDIATE")
    op.execute("SET CONSTRAINTS ALL DEFERRED")
    _replace(_SHAPE)
