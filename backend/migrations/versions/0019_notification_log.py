"""Record of scheduled push notifications already sent, for the tick.

Revision ID: 0019
Revises: 0018
"""

from alembic import op
import sqlalchemy as sa

revision = "0019"
down_revision = "0018"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "notification_log",
        sa.Column(
            "id",
            sa.Uuid(),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column("dedupe_key", sa.Text(), nullable=False),
        sa.Column(
            "sent_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
        sa.CheckConstraint(
            "length(btrim(dedupe_key)) > 0", name="dedupe_key_nonblank"
        ),
        sa.UniqueConstraint(
            "dedupe_key", name="uq_notification_log_dedupe_key"
        ),
    )


def downgrade() -> None:
    op.drop_table("notification_log")
