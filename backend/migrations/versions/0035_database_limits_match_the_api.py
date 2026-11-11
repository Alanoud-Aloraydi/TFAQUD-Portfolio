"""Every length and range the API checks is checked by the database too.

The circle name, the names of a patient without an account, the city and
the zone had only a "not blank" rule here while the API counted their
characters; the patient's birth date had no floor here while the account's
has one; an appointment's status came only from the server's code; and the
conditions of a reading or a reading time could repeat. Each limit is now
the same in both places. A row that breaks a limit stops the upgrade with
its table named, since only test data exists.

Revision ID: 0035
Revises: 0034
"""
from alembic import op
import sqlalchemy as sa

revision = "0035"
down_revision = "0034"
branch_labels = None
depends_on = None

_NO_REPEATS = (
    "fn_measurement_conditions_unique(conditions)"
)
_NAME_SOURCE_OLD = (
    "(account_id IS NOT NULL AND first_name IS NULL AND last_name IS NULL) "
    "OR (account_id IS NULL AND first_name IS NOT NULL "
    "AND last_name IS NOT NULL AND length(btrim(first_name)) > 0 "
    "AND length(btrim(last_name)) > 0)"
)
_NAME_SOURCE_NEW = (
    "(account_id IS NOT NULL AND first_name IS NULL AND last_name IS NULL) "
    "OR (account_id IS NULL AND first_name IS NOT NULL "
    "AND last_name IS NOT NULL "
    "AND length(btrim(first_name)) BETWEEN 1 AND 50 "
    "AND length(btrim(last_name)) BETWEEN 1 AND 50)"
)
_LIMITS = (
    # (table, old constraint, new constraint, new rule, old rule)
    (
        "care_circle", "name_nonblank", "name",
        "length(btrim(name)) BETWEEN 1 AND 60", "length(btrim(name)) > 0",
    ),
    ("patient", "name_source", "name_source", _NAME_SOURCE_NEW,
     _NAME_SOURCE_OLD),
    (
        "patient", "city_nonblank", "city",
        "length(btrim(city)) BETWEEN 1 AND 60", "length(btrim(city)) > 0",
    ),
    (
        "patient", "time_zone_nonblank", "time_zone",
        "length(btrim(time_zone)) BETWEEN 1 AND 64",
        "length(btrim(time_zone)) > 0",
    ),
)


def _refuse_rows_outside(table: str, rule: str) -> None:
    """Stop with a clear message when a row would break the new rule."""
    count = op.get_bind().execute(sa.text(
        f"SELECT count(*) FROM {table} WHERE NOT ({rule})"
    )).scalar_one()
    if count:
        raise RuntimeError(
            f"{count} row(s) of {table} break the limit {rule!r}; "
            "fix them before this migration."
        )


def upgrade() -> None:
    op.execute("""
        CREATE FUNCTION fn_measurement_conditions_unique(items text[])
        RETURNS boolean LANGUAGE sql IMMUTABLE STRICT AS $$
            SELECT cardinality(items) =
                cardinality(ARRAY(SELECT DISTINCT unnest(items)));
        $$;
    """)
    for table, old, new, rule, _ in _LIMITS:
        _refuse_rows_outside(table, rule)
        op.drop_constraint(op.f(f"ck_{table}_{old}"), table, type_="check")
        op.create_check_constraint(op.f(f"ck_{table}_{new}"), table, rule)
    _refuse_rows_outside("patient", "birth_date >= DATE '1900-01-01'")
    op.create_check_constraint(
        op.f("ck_patient_birth_date"), "patient",
        "birth_date >= DATE '1900-01-01'",
    )
    op.alter_column(
        "appointment", "status", server_default=sa.text("'scheduled'")
    )
    for table in ("measurement_plan_time", "measurement_record"):
        _refuse_rows_outside(table, _NO_REPEATS)
        op.create_check_constraint(
            op.f(f"ck_{table}_conditions_once"), table, _NO_REPEATS
        )


def downgrade() -> None:
    for table in ("measurement_plan_time", "measurement_record"):
        op.drop_constraint(
            op.f(f"ck_{table}_conditions_once"), table, type_="check"
        )
    op.execute("DROP FUNCTION fn_measurement_conditions_unique(text[])")
    op.alter_column("appointment", "status", server_default=None)
    op.drop_constraint(op.f("ck_patient_birth_date"), "patient", type_="check")
    for table, old, new, _, rule in reversed(_LIMITS):
        op.drop_constraint(op.f(f"ck_{table}_{new}"), table, type_="check")
        op.create_check_constraint(op.f(f"ck_{table}_{old}"), table, rule)
