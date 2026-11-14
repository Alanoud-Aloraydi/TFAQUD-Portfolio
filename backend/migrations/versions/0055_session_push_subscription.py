"""Each sign-in remembers its phone's OneSignal subscription.

The app sends the id of its phone's OneSignal subscription after signing in.
When OneSignal reports that the phone's app was deleted, the sign-in it
belongs to ends, as a sign-out would (app/push/notify.py). Empty for the
sign-ins made before: their apps send it when they next open.

Revision ID: 0055
Revises: 0054
"""
from alembic import op
import sqlalchemy as sa

revision = "0055"
down_revision = "0054"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "account_session",
        sa.Column("push_subscription_id", sa.Uuid(), nullable=True),
    )
    op.create_unique_constraint(
        "uq_account_session_push_subscription_id",
        "account_session",
        ["push_subscription_id"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "uq_account_session_push_subscription_id",
        "account_session",
        type_="unique",
    )
    op.drop_column("account_session", "push_subscription_id")
