"""One leader per circle, edit permission per area, longer snoozes.

The leader («قائد الدائرة») removes members and lets each one edit the
medicines, the measurements and the appointments, or not. It is the patient
while they use the detailed mode; otherwise the account `leader_account_id`
names: whoever made the circle, or whoever the leader handed it to. One that
left the circle is replaced by the member who joined first
(`app.circles.leader`).

Each membership's one `can_edit` becomes three flags, one per area, all
copied from it. A membership remembers when it joined (`created_at`); rows
older than this migration share its time.

«ذكّرني لاحقًا» may put a task off for up to 12 hours (720 minutes), not 4.

Revision ID: 0048
Revises: 0047
"""
from alembic import op
import sqlalchemy as sa

revision = "0048"
down_revision = "0047"
branch_labels = None
depends_on = None

AREAS = ("medications", "measurements", "appointments")
_MANAGER = "care_circle_manager"


def _snooze_range(top: int) -> None:
    name = op.f("ck_task_snooze_minutes_range")
    op.drop_constraint(name, "task_snooze", type_="check")
    op.create_check_constraint(
        name, "task_snooze", f"minutes BETWEEN 1 AND {top}"
    )


def _run_pending_checks() -> None:
    """The deferred checks waiting from an update run now: PostgreSQL alters
    no table with checks still pending in the same transaction. Every
    deferrable check of this database is deferred at first, so they are
    deferred again after."""
    op.execute("SET CONSTRAINTS ALL IMMEDIATE")
    op.execute("SET CONSTRAINTS ALL DEFERRED")


def upgrade() -> None:
    for area in AREAS:
        op.add_column(
            _MANAGER,
            sa.Column(
                f"can_edit_{area}",
                sa.Boolean(),
                nullable=False,
                server_default=sa.text("true"),
            ),
        )
    op.add_column(
        _MANAGER,
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("now()"),
        ),
    )
    op.execute(
        f"UPDATE {_MANAGER} SET "
        + ", ".join(f"can_edit_{area} = can_edit" for area in AREAS)
    )
    _run_pending_checks()
    op.drop_column(_MANAGER, "can_edit")

    op.add_column(
        "care_circle",
        sa.Column(
            "leader_account_id",
            sa.Uuid(),
            sa.ForeignKey(
                "account.id",
                name=op.f("fk_care_circle_leader_account_id_account"),
                ondelete="SET NULL",
            ),
            nullable=True,
        ),
    )
    # Who made each circle: the sender of the request it came from, else its
    # patient when they manage it, else its first manager.
    op.execute("""
        UPDATE care_circle c SET leader_account_id = coalesce(
            (SELECT r.requested_by_account_id FROM care_circle_request r
             JOIN care_circle_manager m
               ON m.care_circle_id = c.id
              AND m.account_id = r.requested_by_account_id
             WHERE r.care_circle_id = c.id AND r.status = 'completed'
             LIMIT 1),
            (SELECT m.account_id FROM care_circle_manager m
             WHERE m.care_circle_id = c.id AND m.account_id = c.account_id),
            (SELECT m.account_id FROM care_circle_manager m
             WHERE m.care_circle_id = c.id
             ORDER BY m.account_id LIMIT 1)
        )
    """)

    _run_pending_checks()
    _snooze_range(720)


def downgrade() -> None:
    # A snooze longer than the old 4 hours is a moment's state; it goes.
    op.execute("DELETE FROM task_snooze WHERE minutes > 240")
    _run_pending_checks()
    _snooze_range(240)

    op.drop_column("care_circle", "leader_account_id")
    op.drop_column(_MANAGER, "created_at")
    op.add_column(
        _MANAGER,
        sa.Column(
            "can_edit",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
    )
    # Editing stays on only where every area was on.
    op.execute(
        f"UPDATE {_MANAGER} SET can_edit = "
        + " AND ".join(f"can_edit_{area}" for area in AREAS)
    )
    _run_pending_checks()
    for area in AREAS:
        op.drop_column(_MANAGER, f"can_edit_{area}")
