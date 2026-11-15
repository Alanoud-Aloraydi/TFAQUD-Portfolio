"""Pushes go through OneSignal: the server keeps no phone tokens.

The app ties its phone to the signed-in account in OneSignal (the account's
id is OneSignal's external id), and the server sends to the account. The
Apple tokens kept per sign-in (`push_device`) are no longer read, so the
table goes. Going back makes it again, empty: each app sends its token
again when it opens.

Revision ID: 0054
Revises: 0053
"""
from alembic import op
import sqlalchemy as sa

revision = "0054"
down_revision = "0053"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_table("push_device")


def downgrade() -> None:
    op.create_table(
        "push_device",
        sa.Column(
            "id", sa.Uuid(), server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("token", sa.Text(), nullable=False),
        sa.Column("session_id", sa.Uuid(), nullable=False),
        sa.Column(
            "created_at", sa.DateTime(timezone=True),
            server_default=sa.text("now()"), nullable=False,
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True),
            server_default=sa.text("now()"), nullable=False,
        ),
        sa.CheckConstraint(
            "token ~ '^[0-9a-f]{64,200}$'",
            name=op.f("ck_push_device_token_format"),
        ),
        sa.CheckConstraint(
            "updated_at >= created_at",
            name=op.f("ck_push_device_update_order"),
        ),
        sa.ForeignKeyConstraint(
            ["session_id"], ["account_session.id"], ondelete="CASCADE",
            name=op.f("fk_push_device_session_id_account_session"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_push_device")),
        sa.UniqueConstraint("token", name=op.f("uq_push_device_token")),
    )
    op.create_index(
        op.f("ix_push_device_session_id"), "push_device", ["session_id"]
    )
