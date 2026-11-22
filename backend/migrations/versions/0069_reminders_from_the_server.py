"""The reminders at a task's time can come from the server.

`account_session.server_reminders`: the app on this sign-in's phone leaves
the reminders at a dose's, a reading's and an appointment's time to the
server, which sends each one at its time with the plan as it is then
(app/push/scheduled/reminders). The app asks with its push subscription;
the phone then sets none of its own, so nobody gets the same reminder
twice. False for the sign-ins made before: their apps keep setting their
own.

`notification_log` keeps each of those reminders once, as it keeps a missed
task: the kinds `dose_reminder` and `measurement_reminder`, and an
appointment's `appointment_day_before`, `appointment_soon` and
`appointment_today`. Each has the task's time of day, so a dose or a visit
moved to another time is reminded of again.

Revision ID: 0069
Revises: 0068
"""
import sqlalchemy as sa
from alembic import op

revision = "0069"
down_revision = "0068"
branch_labels = None
depends_on = None

_LOG = "notification_log"
_KIND = "ck_notification_log_kind"
_TIME = "ck_notification_log_time_of_day"
_MISSED = "'dose_missed', 'measurement_missed', 'appointment_missed'"
_REMINDERS = (
    "'dose_reminder', 'measurement_reminder', 'appointment_day_before', "
    "'appointment_soon', 'appointment_today'"
)


def upgrade() -> None:
    op.add_column(
        "account_session",
        sa.Column(
            "server_reminders",
            sa.Boolean(),
            server_default=sa.false(),
            nullable=False,
        ),
    )
    op.drop_constraint(op.f(_KIND), _LOG, type_="check")
    op.create_check_constraint(
        op.f(_KIND), _LOG, f"kind IN ({_MISSED}, {_REMINDERS})"
    )
    # Only a missed dose and a missed appointment have no time: one of each
    # per day.
    op.drop_constraint(op.f(_TIME), _LOG, type_="check")
    op.create_check_constraint(
        op.f(_TIME), _LOG,
        "(kind IN ('dose_missed', 'appointment_missed')) "
        "= (time_of_day IS NULL)",
    )


def downgrade() -> None:
    op.execute(f"DELETE FROM {_LOG} WHERE kind IN ({_REMINDERS})")
    op.drop_constraint(op.f(_TIME), _LOG, type_="check")
    op.create_check_constraint(
        op.f(_TIME), _LOG,
        "(kind = 'measurement_missed') = (time_of_day IS NOT NULL)",
    )
    op.drop_constraint(op.f(_KIND), _LOG, type_="check")
    op.create_check_constraint(op.f(_KIND), _LOG, f"kind IN ({_MISSED})")
    op.drop_column("account_session", "server_reminders")
