"""«نذكرك كل … يوم»: a medicine dose every few days.

A schedule can repeat every `interval_days` days (1 to 90), counted from
the day the treatment starts: every 3 days from 1 November is 1, 4, 7 ...
It has no weekdays and no days of the month. The app offers this in place
of «شهري»; a monthly schedule already saved stays monthly.

Two doses every few days at one time would meet on the first day, so one
dose time is weekly, monthly, or one interval schedule. The database's own
medication rules learn the same, and a dose record's date must be on its
schedule's interval.

Revision ID: 0026
Revises: 0025
"""

import importlib.util
from pathlib import Path

from alembic import op
import sqlalchemy as sa

revision = "0026"
down_revision = "0025"
branch_labels = None
depends_on = None


def _monthly_migration():
    """Migration 0022, which holds the rules' text as it left them."""
    path = Path(__file__).with_name("0022_medication_monthly_schedules.py")
    spec = importlib.util.spec_from_file_location("migration_0022", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_M0022 = _monthly_migration()

_INTERVAL_DAYS_REQUIRED = _M0022._DAYS_REQUIRED + """
    IF EXISTS (
        SELECT 1 FROM medication_schedule s
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        WHERE v.medication_plan_id = plan_key
          AND s.repeat = 'interval'
          AND (
              EXISTS (
                  SELECT 1 FROM medication_schedule_day d
                  WHERE d.schedule_id = s.id
              )
              OR EXISTS (
                  SELECT 1 FROM medication_schedule_month_day m
                  WHERE m.schedule_id = s.id
              )
          )
    ) THEN
        RAISE EXCEPTION 'An interval schedule has no weekdays or month days'
            USING ERRCODE = '23514';
    END IF;
"""

_OTHER_REPEAT = "              a.repeat <> b.repeat\n"
# Two interval schedules at one time both have a dose on the first day.
_OTHER_REPEAT_OR_INTERVAL = _OTHER_REPEAT + (
    "              OR a.repeat = 'interval'\n"
)

_MONTHLY_DOSE_END = """\
                        ) = extract(day FROM NEW.scheduled_on)::int
                  )
              )
          )
"""
_INTERVAL_DOSE_END = """\
                        ) = extract(day FROM NEW.scheduled_on)::int
                  )
              )
              OR (
                  s.repeat = 'interval'
                  AND (NEW.scheduled_on - v.treatment_starts_on)
                      % s.interval_days = 0
              )
          )
"""

_INTERVAL_CHANGES = {
    "assert_medication_plan": (
        (_M0022._DAYS_REQUIRED, _INTERVAL_DAYS_REQUIRED),
        (_OTHER_REPEAT, _OTHER_REPEAT_OR_INTERVAL),
    ),
    "check_medication_dose": ((_MONTHLY_DOSE_END, _INTERVAL_DOSE_END),),
}

_REPEAT = "ck_medication_schedule_repeat"
_INTERVAL = "ck_medication_schedule_interval_days"


def _rule(name: str, interval: bool) -> None:
    """Reinstall one rule as 0022 left it, with the interval changes or
    without them."""
    source = Path(__file__).with_name("0007_medication_rules.sql")
    rules = source.read_text(encoding="utf-8")
    start = rules.index(f"CREATE FUNCTION {name}(")
    end = rules.index("$$;", start) + 3
    statement = rules[start:end].replace(
        "CREATE FUNCTION", "CREATE OR REPLACE FUNCTION", 1
    )
    changes = (
        _M0022._AFTER_0008[name]
        + _M0022._MONTHLY_CHANGES[name]
        + (_INTERVAL_CHANGES[name] if interval else ())
    )
    for old, new in changes:
        if statement.count(old) != 1:
            raise RuntimeError(f"Unexpected source for medication rule {name}")
        statement = statement.replace(old, new)
    op.execute(statement)


def upgrade() -> None:
    op.add_column(
        "medication_schedule",
        sa.Column("interval_days", sa.SmallInteger(), nullable=True),
    )
    op.drop_constraint(op.f(_REPEAT), "medication_schedule", type_="check")
    op.create_check_constraint(
        op.f(_REPEAT),
        "medication_schedule",
        "repeat IN ('weekly', 'monthly', 'interval')",
    )
    op.create_check_constraint(
        op.f(_INTERVAL),
        "medication_schedule",
        "(repeat = 'interval' AND interval_days IS NOT NULL "
        "AND interval_days BETWEEN 1 AND 90) OR "
        "(repeat <> 'interval' AND interval_days IS NULL)",
    )
    _rule("assert_medication_plan", interval=True)
    _rule("check_medication_dose", interval=True)


def downgrade() -> None:
    interval = op.get_bind().execute(sa.text(
        "SELECT count(*) FROM medication_schedule WHERE repeat = 'interval'"
    )).scalar_one()
    if interval:
        raise RuntimeError("Cannot downgrade interval medication schedules")
    _rule("assert_medication_plan", interval=False)
    _rule("check_medication_dose", interval=False)
    op.drop_constraint(op.f(_INTERVAL), "medication_schedule", type_="check")
    op.drop_constraint(op.f(_REPEAT), "medication_schedule", type_="check")
    op.create_check_constraint(
        op.f(_REPEAT),
        "medication_schedule",
        "repeat IN ('weekly', 'monthly')",
    )
    op.drop_column("medication_schedule", "interval_days")
