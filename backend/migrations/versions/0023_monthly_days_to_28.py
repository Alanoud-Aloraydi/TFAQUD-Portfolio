"""Monthly medicine days are 1 to 28, the days every month has.

The 29th to the 31st are not in every month, so a dose on them would have
to move; the app no longer offers them. A schedule that has one now has
the 28th in its place (only test plans can have them: monthly schedules
came the day before).

Revision ID: 0023
Revises: 0022
"""

from alembic import op

revision = "0023"
down_revision = "0022"
branch_labels = None
depends_on = None

_TABLE = "medication_schedule_month_day"
_CHECK = "ck_medication_schedule_month_day_month_day"


def upgrade() -> None:
    op.execute(
        f"INSERT INTO {_TABLE} (schedule_id, month_day) "
        f"SELECT DISTINCT schedule_id, 28 FROM {_TABLE} WHERE month_day > 28 "
        "ON CONFLICT DO NOTHING"
    )
    op.execute(f"DELETE FROM {_TABLE} WHERE month_day > 28")
    op.drop_constraint(op.f(_CHECK), _TABLE, type_="check")
    op.create_check_constraint(
        op.f(_CHECK), _TABLE, "month_day BETWEEN 1 AND 28"
    )


def downgrade() -> None:
    op.drop_constraint(op.f(_CHECK), _TABLE, type_="check")
    op.create_check_constraint(
        op.f(_CHECK), _TABLE, "month_day BETWEEN 1 AND 31"
    )
