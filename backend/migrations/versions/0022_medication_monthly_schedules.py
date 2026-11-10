"""Monthly medicine schedules: a dose on chosen days of the month.

Each schedule says whether it repeats weekly (its weekdays, as before) or
monthly (its days of the month, 1 to 31, in a new table). Every existing
schedule is weekly. A day the month lacks is the month's last day.

The database's own medication rules learn the same: a weekly schedule has
weekdays only, a monthly one month days only; two doses at one time never
meet on one day; and a dose record's date must be one of its schedule's
days.

Revision ID: 0022
Revises: 0021
"""

from pathlib import Path

from alembic import op
import sqlalchemy as sa

revision = "0022"
down_revision = "0021"
branch_labels = None
depends_on = None

# The rules as migration 0008 left them (0007's text with 0008's changes).
_AFTER_0008 = {
    "assert_medication_plan": (
        (
            "AND effective_until_on IS NULL) <> 1",
            "AND effective_until_on IS NULL\n"
            "          AND cancelled_at IS NULL) <> 1",
        ),
        (
            "WHERE medication_plan_id = plan_key\n"
            "        ) periods",
            "WHERE medication_plan_id = plan_key\n"
            "              AND cancelled_at IS NULL\n"
            "        ) periods",
        ),
    ),
    "check_medication_dose": (
        (
            "AND NEW.scheduled_on >= v.effective_from_on",
            "AND v.cancelled_at IS NULL\n"
            "          AND NEW.scheduled_on >= v.effective_from_on",
        ),
    ),
}

_WEEKDAY_REQUIRED = """    IF EXISTS (
        SELECT 1 FROM medication_schedule s
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        WHERE v.medication_plan_id = plan_key
          AND NOT EXISTS (
              SELECT 1 FROM medication_schedule_day d
              WHERE d.schedule_id = s.id
          )
    ) THEN
        RAISE EXCEPTION 'Each medication schedule requires a weekday'
            USING ERRCODE = '23514';
    END IF;
"""

_DAYS_REQUIRED = """    IF EXISTS (
        SELECT 1 FROM medication_schedule s
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        WHERE v.medication_plan_id = plan_key
          AND s.repeat = 'weekly'
          AND (
              NOT EXISTS (
                  SELECT 1 FROM medication_schedule_day d
                  WHERE d.schedule_id = s.id
              )
              OR EXISTS (
                  SELECT 1 FROM medication_schedule_month_day m
                  WHERE m.schedule_id = s.id
              )
          )
    ) THEN
        RAISE EXCEPTION 'Each medication schedule requires a weekday'
            USING ERRCODE = '23514';
    END IF;

    IF EXISTS (
        SELECT 1 FROM medication_schedule s
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        WHERE v.medication_plan_id = plan_key
          AND s.repeat = 'monthly'
          AND (
              NOT EXISTS (
                  SELECT 1 FROM medication_schedule_month_day m
                  WHERE m.schedule_id = s.id
              )
              OR EXISTS (
                  SELECT 1 FROM medication_schedule_day d
                  WHERE d.schedule_id = s.id
              )
          )
    ) THEN
        RAISE EXCEPTION 'Each monthly schedule requires a day of the month'
            USING ERRCODE = '23514';
    END IF;
"""

_WEEKDAY_OVERLAP_END = (
    "        RAISE EXCEPTION "
    "'Medication times cannot overlap on one weekday'\n"
    "            USING ERRCODE = '23514';\n"
    "    END IF;\n"
)

_MONTH_OVERLAP = _WEEKDAY_OVERLAP_END + """
    IF EXISTS (
        SELECT 1
        FROM medication_schedule s
        JOIN medication_schedule_month_day m ON m.schedule_id = s.id
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        WHERE v.medication_plan_id = plan_key
        GROUP BY v.id, m.month_day, s.time_of_day
        HAVING count(*) > 1
    ) OR EXISTS (
        SELECT 1
        FROM medication_schedule a
        JOIN medication_schedule b
          ON b.plan_version_id = a.plan_version_id
         AND b.time_of_day = a.time_of_day
         AND b.id > a.id
        JOIN medication_plan_version v ON v.id = a.plan_version_id
        WHERE v.medication_plan_id = plan_key
          AND (
              a.repeat <> b.repeat
              OR (
                  a.repeat = 'monthly'
                  AND EXISTS (
                      SELECT 1 FROM medication_schedule_month_day x
                      WHERE x.schedule_id = a.id AND x.month_day >= 28
                  )
                  AND EXISTS (
                      SELECT 1 FROM medication_schedule_month_day y
                      WHERE y.schedule_id = b.id AND y.month_day >= 28
                  )
              )
          )
    ) THEN
        RAISE EXCEPTION 'Medication times cannot overlap on one day'
            USING ERRCODE = '23514';
    END IF;
"""

_DOSE_DAY_JOIN = (
    "        JOIN medication_schedule_day d ON d.schedule_id = s.id\n"
)
_DOSE_WEEKDAY = (
    "          AND d.weekday = extract(isodow FROM NEW.scheduled_on)\n"
)
_DOSE_ANY_DAY = """          AND (
              (
                  s.repeat = 'weekly'
                  AND EXISTS (
                      SELECT 1 FROM medication_schedule_day d
                      WHERE d.schedule_id = s.id
                        AND d.weekday = extract(isodow FROM NEW.scheduled_on)
                  )
              )
              OR (
                  s.repeat = 'monthly'
                  AND EXISTS (
                      SELECT 1 FROM medication_schedule_month_day m
                      WHERE m.schedule_id = s.id
                        AND least(
                            m.month_day,
                            extract(day FROM (
                                date_trunc('month', NEW.scheduled_on)
                                + interval '1 month - 1 day'
                            ))::int
                        ) = extract(day FROM NEW.scheduled_on)::int
                  )
              )
          )
"""

_MONTHLY_CHANGES = {
    "assert_medication_plan": (
        (_WEEKDAY_REQUIRED, _DAYS_REQUIRED),
        (_WEEKDAY_OVERLAP_END, _MONTH_OVERLAP),
    ),
    "check_medication_dose": (
        (_DOSE_DAY_JOIN, ""),
        (_DOSE_WEEKDAY, _DOSE_ANY_DAY),
    ),
}


def _rule(name: str, monthly: bool) -> None:
    """Reinstall one rule as 0008 left it, with the monthly changes or
    without them."""
    source = Path(__file__).with_name("0007_medication_rules.sql")
    rules = source.read_text(encoding="utf-8")
    start = rules.index(f"CREATE FUNCTION {name}(")
    end = rules.index("$$;", start) + 3
    statement = rules[start:end].replace(
        "CREATE FUNCTION", "CREATE OR REPLACE FUNCTION", 1
    )
    changes = _AFTER_0008[name] + (_MONTHLY_CHANGES[name] if monthly else ())
    for old, new in changes:
        if statement.count(old) != 1:
            raise RuntimeError(f"Unexpected source for medication rule {name}")
        statement = statement.replace(old, new)
    op.execute(statement)


def upgrade() -> None:
    op.add_column(
        "medication_schedule",
        sa.Column(
            "repeat",
            sa.Text(),
            server_default=sa.text("'weekly'"),
            nullable=False,
        ),
    )
    op.create_check_constraint(
        op.f("ck_medication_schedule_repeat"),
        "medication_schedule",
        "repeat IN ('weekly', 'monthly')",
    )
    op.create_table(
        "medication_schedule_month_day",
        sa.Column("schedule_id", sa.Uuid(), nullable=False),
        sa.Column("month_day", sa.SmallInteger(), nullable=False),
        sa.CheckConstraint(
            "month_day BETWEEN 1 AND 31",
            name=op.f("ck_medication_schedule_month_day_month_day"),
        ),
        sa.ForeignKeyConstraint(
            ["schedule_id"],
            ["medication_schedule.id"],
            ondelete="CASCADE",
            name=op.f(
                "fk_medication_schedule_month_day_schedule_id_"
                "medication_schedule"
            ),
        ),
        sa.PrimaryKeyConstraint(
            "schedule_id",
            "month_day",
            name=op.f("pk_medication_schedule_month_day"),
        ),
    )
    # The same locking and deferred plan check as the weekday rows.
    op.execute(
        "CREATE TRIGGER lock_medication_month_day_patient "
        "BEFORE INSERT OR UPDATE OR DELETE ON medication_schedule_month_day "
        "FOR EACH ROW EXECUTE FUNCTION lock_medication_patient()"
    )
    op.execute(
        "CREATE CONSTRAINT TRIGGER check_medication_month_day_complete "
        "AFTER INSERT OR UPDATE OR DELETE ON medication_schedule_month_day "
        "DEFERRABLE INITIALLY DEFERRED "
        "FOR EACH ROW EXECUTE FUNCTION check_medication_plan()"
    )
    _rule("assert_medication_plan", monthly=True)
    _rule("check_medication_dose", monthly=True)


def downgrade() -> None:
    monthly = op.get_bind().execute(sa.text(
        "SELECT count(*) FROM medication_schedule WHERE repeat = 'monthly'"
    )).scalar_one()
    if monthly:
        raise RuntimeError("Cannot downgrade monthly medication schedules")
    _rule("assert_medication_plan", monthly=False)
    _rule("check_medication_dose", monthly=False)
    op.drop_table("medication_schedule_month_day")
    op.drop_constraint(
        op.f("ck_medication_schedule_repeat"),
        "medication_schedule",
        type_="check",
    )
    op.drop_column("medication_schedule", "repeat")
