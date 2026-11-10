"""More than one reading time a day in a measurement plan.

A version's reading times move to their own table (one row each, with the
glucose context of that time: fasting at 07:00, after a meal at 14:00).
The version keeps `time_of_day` and `glucose_context` as a copy of its
first time. A planned record says which time of its day it answers, so a
day can have one outcome per time.

Every existing version gets its one time; every existing planned record
gets its version's time.

Revision ID: 0024
Revises: 0023
"""

from alembic import op
import sqlalchemy as sa

revision = "0024"
down_revision = "0023"
branch_labels = None
depends_on = None

_CONTEXTS = (
    "glucose_context IS NULL OR glucose_context IN "
    "('fasting', 'before_meal', 'after_meal', 'bedtime', 'other')"
)


def upgrade() -> None:
    op.create_table(
        "measurement_plan_time",
        sa.Column("version_id", sa.Uuid(), nullable=False),
        sa.Column("time_of_day", sa.Time(), nullable=False),
        sa.Column("glucose_context", sa.Text(), nullable=True),
        sa.CheckConstraint(
            _CONTEXTS, name=op.f("ck_measurement_plan_time_glucose_context")
        ),
        sa.ForeignKeyConstraint(
            ["version_id"],
            ["measurement_plan_version.id"],
            ondelete="CASCADE",
            name=op.f(
                "fk_measurement_plan_time_version_id_measurement_plan_version"
            ),
        ),
        sa.PrimaryKeyConstraint(
            "version_id",
            "time_of_day",
            name=op.f("pk_measurement_plan_time"),
        ),
    )
    op.execute(
        "INSERT INTO measurement_plan_time "
        "(version_id, time_of_day, glucose_context) "
        "SELECT id, time_of_day, glucose_context FROM measurement_plan_version"
    )
    op.add_column(
        "measurement_record",
        sa.Column("scheduled_time", sa.Time(), nullable=True),
    )
    op.execute(
        "UPDATE measurement_record r SET scheduled_time = v.time_of_day "
        "FROM measurement_plan_version v WHERE v.id = r.plan_version_id"
    )
    op.drop_constraint(
        op.f("uq_measurement_record_plan_version_id"),
        "measurement_record",
        type_="unique",
    )
    op.create_unique_constraint(
        op.f("uq_measurement_record_plan_version_id"),
        "measurement_record",
        ["plan_version_id", "scheduled_on", "scheduled_time"],
    )
    op.drop_constraint(
        op.f("ck_measurement_record_schedule_pair"),
        "measurement_record",
        type_="check",
    )
    op.create_check_constraint(
        op.f("ck_measurement_record_schedule_pair"),
        "measurement_record",
        "(plan_version_id IS NULL AND scheduled_on IS NULL "
        "AND scheduled_time IS NULL) OR "
        "(plan_version_id IS NOT NULL AND scheduled_on IS NOT NULL "
        "AND scheduled_time IS NOT NULL)",
    )


def downgrade() -> None:
    extra = op.get_bind().execute(sa.text(
        "SELECT count(*) FROM measurement_plan_time t "
        "JOIN measurement_plan_version v ON v.id = t.version_id "
        "WHERE t.time_of_day <> v.time_of_day"
    )).scalar_one()
    if extra:
        raise RuntimeError("Cannot downgrade plans with several reading times")
    op.drop_constraint(
        op.f("ck_measurement_record_schedule_pair"),
        "measurement_record",
        type_="check",
    )
    op.create_check_constraint(
        op.f("ck_measurement_record_schedule_pair"),
        "measurement_record",
        "(plan_version_id IS NULL AND scheduled_on IS NULL) OR "
        "(plan_version_id IS NOT NULL AND scheduled_on IS NOT NULL)",
    )
    op.drop_constraint(
        op.f("uq_measurement_record_plan_version_id"),
        "measurement_record",
        type_="unique",
    )
    op.create_unique_constraint(
        op.f("uq_measurement_record_plan_version_id"),
        "measurement_record",
        ["plan_version_id", "scheduled_on"],
    )
    op.drop_column("measurement_record", "scheduled_time")
    op.drop_table("measurement_plan_time")
