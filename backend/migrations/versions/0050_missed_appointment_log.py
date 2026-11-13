"""The tick also tells of a missed appointment, once.

`notification_log` gets the kind `appointment_missed`: an appointment two
hours past its time that nobody marked visited or cancelled. Its target is
the appointment, its day the appointment's day, and it has no time (one
message per appointment).

Revision ID: 0050
Revises: 0049
"""
from alembic import op

revision = "0050"
down_revision = "0049"
branch_labels = None
depends_on = None

_LOG = "notification_log"
_KIND = "ck_notification_log_kind"


def upgrade() -> None:
    op.drop_constraint(op.f(_KIND), _LOG, type_="check")
    op.create_check_constraint(
        op.f(_KIND), _LOG,
        "kind IN ('dose_missed', 'measurement_missed', 'appointment_missed')",
    )


def downgrade() -> None:
    op.execute(f"DELETE FROM {_LOG} WHERE kind = 'appointment_missed'")
    op.drop_constraint(op.f(_KIND), _LOG, type_="check")
    op.create_check_constraint(
        op.f(_KIND), _LOG, "kind IN ('dose_missed', 'measurement_missed')"
    )
