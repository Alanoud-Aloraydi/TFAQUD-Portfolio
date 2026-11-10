"""A sign-in ends only when it is signed out: refresh tokens have no end date.

Before, a refresh token ended 30 days after the sign-in, and the person had
to sign in again. Now the session lasts until it is revoked: by signing out,
by deleting the account, or by the server when Apple says the app was
deleted from the phone (`app.push.notify`).

A session that had already ended by the old rule stays ended: it is marked
signed out at the time it ended. Every other session simply keeps going.

Going back gives every live session 30 days from the downgrade (never less
than 30 days from its start), so a downgrade does not sign everyone out.

Revision ID: 0031
Revises: 0030
"""

from alembic import op
import sqlalchemy as sa

revision = "0031"
down_revision = "0030"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("""
        UPDATE account_session
        SET revoked_at = refresh_expires_at
        WHERE revoked_at IS NULL AND refresh_expires_at <= now()
    """)
    op.drop_constraint(
        op.f("ck_account_session_expiry_order"),
        "account_session",
        type_="check",
    )
    op.drop_column("account_session", "refresh_expires_at")


def downgrade() -> None:
    op.add_column(
        "account_session",
        sa.Column("refresh_expires_at", sa.DateTime(timezone=True)),
    )
    op.execute("""
        UPDATE account_session
        SET refresh_expires_at = GREATEST(created_at, now())
            + interval '30 days'
    """)
    op.alter_column("account_session", "refresh_expires_at", nullable=False)
    op.create_check_constraint(
        op.f("ck_account_session_expiry_order"),
        "account_session",
        "refresh_expires_at > created_at",
    )
