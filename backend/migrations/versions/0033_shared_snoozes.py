"""«ذكّرني لاحقًا» is shared by the circle.

Before, a task put off was kept only on the phone that put it off, so no
one else in the circle knew. Now the server keeps it: every member sees
who put it off and until when, and when that time comes every member is
reminded (app/snoozes).

Revision ID: 0033
Revises: 0032
"""

from alembic import op
import sqlalchemy as sa

revision = "0033"
down_revision = "0032"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "task_snooze",
        sa.Column(
            "id",
            sa.Uuid(),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "care_circle_id",
            sa.Uuid(),
            sa.ForeignKey("care_circle.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("task", sa.Text(), nullable=False),
        sa.Column("task_id", sa.Uuid(), nullable=False),
        sa.Column("scheduled_on", sa.Date(), nullable=False),
        sa.Column("time_of_day", sa.Time(), nullable=False),
        sa.Column("minutes", sa.Integer(), nullable=False),
        sa.Column("remind_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "snoozed_by_account_id",
            sa.Uuid(),
            sa.ForeignKey("account.id", ondelete="SET NULL"),
        ),
        sa.Column("snoozed_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("notified_at", sa.DateTime(timezone=True)),
        sa.CheckConstraint(
            "task IN ('dose', 'measurement')", name="task_kind"
        ),
        sa.CheckConstraint(
            "minutes BETWEEN 1 AND 240", name="minutes_range"
        ),
        sa.CheckConstraint("remind_at > snoozed_at", name="remind_order"),
        sa.UniqueConstraint(
            "task", "task_id", "scheduled_on", "time_of_day",
            name=op.f("uq_task_snooze_task"),
        ),
    )
    op.create_index(
        "ix_task_snooze_care_circle_id", "task_snooze", ["care_circle_id"]
    )
    # The scan for tasks whose new time came reads only those still waiting.
    op.create_index(
        "ix_task_snooze_waiting",
        "task_snooze",
        ["remind_at"],
        postgresql_where=sa.text("notified_at IS NULL"),
    )


def downgrade() -> None:
    op.drop_index("ix_task_snooze_waiting", table_name="task_snooze")
    op.drop_index("ix_task_snooze_care_circle_id", table_name="task_snooze")
    op.drop_table("task_snooze")
