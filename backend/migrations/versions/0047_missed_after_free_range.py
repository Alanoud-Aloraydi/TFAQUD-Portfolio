"""Let a plan's «missed after» be any number of minutes from 5 to 360.

It was one of 30, 60 or 120. The same range is the request schema's
(`app/plan_limits.py`) and the app's.

Revision ID: 0047
Revises: 0046
"""
from alembic import op

revision = "0047"
down_revision = "0046"
branch_labels = None
depends_on = None

_TABLES = ("medication_plan_version", "measurement_plan_version")


def _constraint(table: str) -> str:
    return f"ck_{table}_missed_after_minutes"


def _replace(condition: str) -> None:
    for table in _TABLES:
        op.drop_constraint(_constraint(table), table, type_="check")
        op.create_check_constraint(_constraint(table), table, condition)


def upgrade() -> None:
    _replace("missed_after_minutes BETWEEN 5 AND 360")


def downgrade() -> None:
    """Refuse when a value outside the old three choices is stored."""
    for table in _TABLES:
        stored = op.get_bind().exec_driver_sql(
            f"SELECT count(*) FROM {table} "
            "WHERE missed_after_minutes NOT IN (30, 60, 120)"
        ).scalar()
        if stored:
            raise RuntimeError(
                f"{table} holds a «missed after» other than 30, 60 or 120 "
                "minutes; change those versions before downgrading"
            )
    _replace("missed_after_minutes IN (30, 60, 120)")
