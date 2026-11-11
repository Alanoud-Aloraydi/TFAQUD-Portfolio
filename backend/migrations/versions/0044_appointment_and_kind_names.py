"""Last names and the companion rule that moved to the server.

- An appointment's words for «أخرى» are `other_text`, as in the medical
  file and a reading.
- The measurement kind `bp` is `blood_pressure`, a full word beside
  `glucose`.
- The account columns an account's deletion empties are indexed, so the
  deletion does not read the whole table.
- Every column that may be empty, and every copy kept as history, says why
  in a comment.

Revision ID: 0044
Revises: 0043
"""
from alembic import op

revision = "0044"
down_revision = "0043"
branch_labels = None
depends_on = None

_KIND_TABLES = (
    "measurement_plan", "measurement_target", "measurement_reading"
)
_AUDIT_INDEXES = (
    ("appointment", "created_by_account_id"),
    ("appointment", "updated_by_account_id"),
    ("appointment_visit", "updated_by_account_id"),
    ("measurement_plan", "created_by_account_id"),
    ("measurement_plan_version", "created_by_account_id"),
)
COMMENTS = {
    ("account", "first_name"): "Null until onboarding saves the profile.",
    ("account", "app_mode"): "Null until the account first joins care.",
    ("account", "birth_date"): "Null for an account made before onboarding "
    "asked; required once the account is a patient.",
    ("care_circle", "name"): "The patient's own name for the circle; null "
    "for a patient without an account (others read «دائرة» and the name).",
    ("care_circle", "account_id"): "The patient's account; null for a "
    "patient without one.",
    ("care_circle", "first_name"): "Only for a patient without an account; "
    "an account's patient reads the account's names.",
    ("care_circle", "birth_date"): "Only for a patient without an account.",
    ("care_circle", "conditions_status"): "Null until the question is "
    "answered; none or listed.",
    ("care_circle", "allergies_status"): "Null until the question is "
    "answered; none or listed.",
    ("otp_request", "expires_at"): "Null until the first code is sent.",
    ("medication_plan_version", "normalized_name"): "Derived key of name "
    "(NFKC, casefold, one space) that the overlap rule compares.",
    ("measurement_plan_version", "glucose_low"): "Snapshot: the target "
    "this version judged readings by.",
    ("measurement_reading", "glucose_low"): "Snapshot: the target a "
    "reading without a plan was judged by.",
    ("measurement_reading", "plan_version_id"): "Null for a reading taken "
    "outside a plan.",
}


def _rename_kind(old: str, new: str) -> None:
    """Change the kind code in the rows and in every check that names it."""
    tables = ", ".join(f"'{table}'" for table in _KIND_TABLES)
    op.execute(f"""
    DO $$
    DECLARE item record;
    BEGIN
        CREATE TEMP TABLE kind_checks ON COMMIT DROP AS
        SELECT conrelid::regclass::text AS tab, conname AS name,
               pg_get_constraintdef(oid) AS rule
        FROM pg_constraint
        WHERE contype = 'c'
          AND conrelid::regclass::text IN ({tables})
          AND pg_get_constraintdef(oid) LIKE '%''{old}''%';
        FOR item IN SELECT * FROM kind_checks LOOP
            EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I',
                item.tab, item.name);
        END LOOP;
        UPDATE measurement_plan SET kind = '{new}' WHERE kind = '{old}';
        UPDATE measurement_target SET kind = '{new}' WHERE kind = '{old}';
        UPDATE measurement_reading SET kind = '{new}' WHERE kind = '{old}';
        FOR item IN SELECT * FROM kind_checks LOOP
            EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I %s',
                item.tab, item.name,
                replace(item.rule, '''{old}''', '''{new}'''));
        END LOOP;
        DROP TABLE kind_checks;
    END $$;
    """)


def upgrade() -> None:
    op.alter_column("appointment", "other_kind", new_column_name="other_text")
    op.execute(
        "ALTER TABLE appointment RENAME CONSTRAINT "
        "ck_appointment_other_kind_shape TO ck_appointment_other_text"
    )
    _rename_kind("bp", "blood_pressure")
    for table, column in _AUDIT_INDEXES:
        op.create_index(op.f(f"ix_{table}_{column}"), table, [column])
    for (table, column), text in COMMENTS.items():
        op.execute(
            f"COMMENT ON COLUMN {table}.{column} IS "
            f"'{text.replace(chr(39), chr(39) * 2)}'"
        )


def downgrade() -> None:
    for table, column in COMMENTS:
        op.execute(f"COMMENT ON COLUMN {table}.{column} IS NULL")
    for table, column in reversed(_AUDIT_INDEXES):
        op.drop_index(op.f(f"ix_{table}_{column}"), table_name=table)
    _rename_kind("blood_pressure", "bp")
    op.execute(
        "ALTER TABLE appointment RENAME CONSTRAINT "
        "ck_appointment_other_text TO ck_appointment_other_kind_shape"
    )
    op.alter_column("appointment", "other_text", new_column_name="other_kind")
