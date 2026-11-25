"""Remove what nothing reads any more.

- `measurement_target`: the targets saved for readings without a plan.
  Fixed normal ranges replaced them; no code reads or writes the table.
- The four target columns of `measurement_plan_version` and of
  `measurement_reading` (`glucose_low`, `glucose_high`, `systolic_limit`,
  `diastolic_limit`): new rows leave them empty, and nothing reads the old
  values. Their shape checks go with them.
- `task_snooze.snoozed_at`: never read, and always `remind_at` less
  `minutes`. Its order check goes with it; `minutes` stays checked.

Going back makes the table and the columns again, empty: the values this
removes do not come back. Take a backup first.

Revision ID: 0071
Revises: 0070
"""

from alembic import op
import sqlalchemy as sa

revision = "0071"
down_revision = "0070"
branch_labels = None
depends_on = None

TARGET_COLUMNS = ("glucose_low", "glucose_high", "systolic_limit",
                  "diastolic_limit")

# The four targets of one kind: glucose low and high, or the two limits of
# blood pressure, each 1 to 999, the first below the second.
GLUCOSE = (
    "glucose_low IS NOT NULL AND glucose_high IS NOT NULL "
    "AND glucose_low BETWEEN 1 AND 999 AND glucose_high BETWEEN 1 AND 999 "
    "AND glucose_low < glucose_high "
    "AND systolic_limit IS NULL AND diastolic_limit IS NULL"
)
PRESSURE = (
    "systolic_limit IS NOT NULL AND diastolic_limit IS NOT NULL "
    "AND systolic_limit BETWEEN 1 AND 999 "
    "AND diastolic_limit BETWEEN 1 AND 999 "
    "AND systolic_limit > diastolic_limit "
    "AND glucose_low IS NULL AND glucose_high IS NULL"
)
NONE = (
    "glucose_low IS NULL AND glucose_high IS NULL "
    "AND systolic_limit IS NULL AND diastolic_limit IS NULL"
)


def upgrade():
    op.drop_table("measurement_target")
    for table, check in (
        ("measurement_plan_version", "target_shape"),
        ("measurement_reading", "free_target_shape"),
    ):
        op.drop_constraint(op.f(f"ck_{table}_{check}"), table, type_="check")
        for column in TARGET_COLUMNS:
            op.drop_column(table, column)
    op.drop_constraint(op.f("ck_task_snooze_remind_order"), "task_snooze",
                       type_="check")
    op.drop_column("task_snooze", "snoozed_at")


def downgrade():
    op.add_column("task_snooze", sa.Column(
        "snoozed_at", sa.DateTime(timezone=True), nullable=True
    ))
    op.execute(
        "UPDATE task_snooze "
        "SET snoozed_at = remind_at - make_interval(mins => minutes)"
    )
    op.alter_column("task_snooze", "snoozed_at", nullable=False)
    op.create_check_constraint(op.f("ck_task_snooze_remind_order"),
                               "task_snooze", "remind_at > snoozed_at")
    for table in ("measurement_plan_version", "measurement_reading"):
        for column in TARGET_COLUMNS:
            op.add_column(table, sa.Column(column, sa.SmallInteger()))
    op.create_check_constraint(
        op.f("ck_measurement_plan_version_target_shape"),
        "measurement_plan_version",
        f"({NONE}) OR ({GLUCOSE}) OR ({PRESSURE})",
    )
    op.create_check_constraint(
        op.f("ck_measurement_reading_free_target_shape"),
        "measurement_reading",
        f"({NONE}) OR (plan_version_id IS NULL AND outcome = 'read' AND ("
        f"(kind = 'glucose' AND {GLUCOSE}) OR "
        f"(kind = 'blood_pressure' AND {PRESSURE})))",
    )
    op.create_table(
        "measurement_target",
        sa.Column("id", sa.Uuid(), server_default=sa.text("gen_random_uuid()"),
                  nullable=False),
        sa.Column("kind", sa.Text(), nullable=False),
        *(sa.Column(column, sa.SmallInteger()) for column in TARGET_COLUMNS),
        sa.Column("care_circle_id", sa.Uuid(), nullable=False),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_measurement_target")),
        sa.UniqueConstraint(
            "care_circle_id", "kind",
            name=op.f("uq_measurement_target_care_circle_id_kind"),
        ),
        sa.ForeignKeyConstraint(
            ["care_circle_id"], ["care_circle.id"], ondelete="CASCADE",
            name=op.f("fk_measurement_target_care_circle_id_care_circle"),
        ),
        sa.CheckConstraint("kind IN ('glucose', 'blood_pressure')",
                           name=op.f("ck_measurement_target_kind")),
        sa.CheckConstraint(
            f"(kind = 'glucose' AND {GLUCOSE}) OR "
            f"(kind = 'blood_pressure' AND {PRESSURE})",
            name=op.f("ck_measurement_target_target_shape"),
        ),
    )
