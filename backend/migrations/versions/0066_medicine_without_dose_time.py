"""A medicine can have no dose time at all (taken when needed, recorded
with «سجّل جرعة الآن»).

The plan check (fn_assert_medication_plan, run when a plan is saved)
still refused a version without a dose time, so such a medicine was
answered as data changed elsewhere. Only that one rule goes; the function
is read from the database, as in 0057, so the rest stays as it is.

Revision ID: 0066
Revises: 0065
"""
from alembic import op
from sqlalchemy import text

revision = "0066"
down_revision = "0065"
branch_labels = None
depends_on = None

_NEEDS_SCHEDULE = """    IF EXISTS (
        SELECT 1 FROM medication_plan_version v
        WHERE v.medication_plan_id = plan_key
          AND NOT EXISTS (
              SELECT 1 FROM medication_schedule s
              WHERE s.plan_version_id = v.id
          )
    ) THEN
        RAISE EXCEPTION 'Each medication version requires a schedule'
            USING ERRCODE = '23514';
    END IF;
"""
# The rule after it, where the downgrade puts it back.
_WEEKDAY_RULE = """    IF EXISTS (
        SELECT 1 FROM medication_schedule s
        JOIN medication_plan_version v ON v.id = s.plan_version_id
        WHERE v.medication_plan_id = plan_key
          AND s.repeat = 'weekly'
"""


def _rewrite(old: str, new: str) -> None:
    source = op.get_bind().execute(
        text(
            "SELECT pg_get_functiondef("
            "'fn_assert_medication_plan(uuid)'::regprocedure)"
        )
    ).scalar_one()
    if source.count(old) != 1:
        raise RuntimeError("fn_assert_medication_plan is not as expected")
    op.execute(source.replace(old, new))


def upgrade() -> None:
    _rewrite(_NEEDS_SCHEDULE, "")


def downgrade() -> None:
    # A medicine saved without a dose time is refused again only when it
    # is next saved.
    _rewrite(_WEEKDAY_RULE, _NEEDS_SCHEDULE + _WEEKDAY_RULE)
