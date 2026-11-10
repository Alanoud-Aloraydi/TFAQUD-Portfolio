"""Keep the Apple push token of each signed-in phone."""

from alembic import op
import sqlalchemy as sa

revision = "0017"
down_revision = "0016"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """A token is removed with its sign-in and with its account."""
    op.create_table(
        "push_device",
        sa.Column("token", sa.Text(), primary_key=True),
        sa.Column(
            "account_id",
            sa.Uuid(),
            sa.ForeignKey("account.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "session_id",
            sa.Uuid(),
            sa.ForeignKey("account_session.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "token ~ '^[0-9a-f]{64,200}$'", name="token_format"
        ),
        sa.CheckConstraint("updated_at >= created_at", name="update_order"),
    )
    op.create_index(
        "ix_push_device_account_id", "push_device", ["account_id"]
    )
    op.create_index(
        "ix_push_device_session_id", "push_device", ["session_id"]
    )


def downgrade() -> None:
    op.drop_index("ix_push_device_session_id", table_name="push_device")
    op.drop_index("ix_push_device_account_id", table_name="push_device")
    op.drop_table("push_device")
