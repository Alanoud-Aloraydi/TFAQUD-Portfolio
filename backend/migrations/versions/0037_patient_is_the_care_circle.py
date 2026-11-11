"""The patient's row is the care circle's row.

A circle always had exactly one patient and a patient exactly one circle,
made and deleted together, so the two tables were one thing in two rows.
The patient's columns move onto `care_circle`, every table that pointed at
the patient points at the circle (`care_circle_id`), and `patient` goes.

While the patient has an account, the circle keeps no copy of what the
account already holds: the names, the birth date, the city and the avatar
are read from the account (the birth date and city move onto it here) and
are copied back onto the circle only when the account leaves. A circle's
own `name` is the patient's choice, so a patient without an account has
none (everyone reads «دائرة» and the first name, computed).

Every database rule moves to the new shape, under the names
`fn_<rule>` and `trg_<table>_<rule>`, firing only on the columns each
rule reads (0037_rules.sql).

Revision ID: 0037
Revises: 0036
"""
import importlib.util
from pathlib import Path

from alembic import op
import sqlalchemy as sa

revision = "0037"
down_revision = "0036"
branch_labels = None
depends_on = None

_AVATARS = (
    "('w1_1', 'w1_3', 'w6_1', 'w6_3', 'w7_1', 'w7_3', "
    "'m1_1', 'm1_3', 'm2_1', 'm2_3', 'm6_1', 'm6_3')"
)
_BLOOD = "('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')"
_SOURCE = (
    "(account_id IS NOT NULL AND name IS NOT NULL AND first_name IS NULL "
    "AND last_name IS NULL AND avatar_code IS NULL AND birth_date IS NULL "
    "AND city IS NULL) OR (account_id IS NULL AND name IS NULL "
    "AND first_name IS NOT NULL AND last_name IS NOT NULL "
    "AND birth_date IS NOT NULL AND city IS NOT NULL)"
)
# The checks of the merged circle: (name, rule).
_CIRCLE_CHECKS = (
    ("account_source", _SOURCE),
    ("name", "name IS NULL OR length(btrim(name)) BETWEEN 1 AND 60"),
    (
        "first_name",
        "first_name IS NULL OR length(btrim(first_name)) BETWEEN 1 AND 50",
    ),
    (
        "last_name",
        "last_name IS NULL OR length(btrim(last_name)) BETWEEN 1 AND 50",
    ),
    ("city", "city IS NULL OR length(btrim(city)) BETWEEN 1 AND 60"),
    ("birth_date", "birth_date IS NULL OR birth_date >= DATE '1900-01-01'"),
    ("time_zone", "length(btrim(time_zone)) BETWEEN 1 AND 64"),
    ("latitude", "latitude BETWEEN -90 AND 90"),
    ("longitude", "longitude BETWEEN -180 AND 180"),
    ("blood_type", f"blood_type IN {_BLOOD}"),
    ("avatar_code", f"avatar_code IS NULL OR avatar_code IN {_AVATARS}"),
)
# The tables that pointed at the patient, with the uniques and indexes
# on that column: (table, nullable, [(kind, old name, new name, columns,
# where)]).
_CHILDREN = (
    ("patient_condition", False, (
        ("uq", "uq_patient_condition_patient_id",
         "uq_patient_condition_care_circle_id_code", ["code"], None),
    )),
    ("patient_allergy", False, (
        ("uq", "uq_patient_allergy_patient_id",
         "uq_patient_allergy_care_circle_id_kind_code", ["kind", "code"],
         None),
    )),
    ("emergency_contact", False, (
        ("uq", "uq_emergency_contact_patient_id",
         "uq_emergency_contact_care_circle_id_phone_number",
         ["phone_number"], None),
    )),
    ("medication_plan", False, (
        ("ix", None, "ix_medication_plan_care_circle_id", [], None),
    )),
    ("measurement_plan", False, (
        ("ix", "ix_measurement_plan_patient_id",
         "ix_measurement_plan_care_circle_id", [], None),
        ("uqix", "uq_measurement_plan_active_kind",
         "uq_measurement_plan_care_circle_id_kind_active", ["kind"],
         "stopped_at IS NULL"),
    )),
    ("measurement_target", False, (
        ("uq", "uq_measurement_target_patient_id",
         "uq_measurement_target_care_circle_id_kind", ["kind"], None),
    )),
    ("measurement_record", False, (
        ("ix", "ix_measurement_record_patient_id",
         "ix_measurement_record_care_circle_id", [], None),
    )),
    ("appointment", False, (
        ("ix", "ix_appointment_patient_id", "ix_appointment_care_circle_id",
         [], None),
        ("ix", "ix_appointment_patient_schedule",
         "ix_appointment_care_circle_id_scheduled_on_time_of_day",
         ["scheduled_on", "time_of_day"], None),
    )),
    ("photo", True, (
        ("uq", "uq_photo_patient_id", "uq_photo_care_circle_id", [], None),
    )),
)
_OLD_OWNER = "num_nonnulls(account_id, patient_id, medication_plan_id) = 1"
_NEW_OWNER = (
    "num_nonnulls(account_id, care_circle_id, medication_plan_id) = 1"
)


def _migration(name: str):
    path = Path(__file__).with_name(name)
    spec = importlib.util.spec_from_file_location(name[:-3], path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _sql(name: str) -> str:
    return Path(__file__).with_name(name).read_text(encoding="utf-8")


def _drop_old_rules() -> None:
    for statement in (
        "DROP FUNCTION check_care_circle() CASCADE",
        "DROP FUNCTION assert_care_circle(uuid)",
        "DROP FUNCTION lock_care_parent() CASCADE",
        "DROP FUNCTION guard_account_care() CASCADE",
        "DROP FUNCTION check_medication_dose() CASCADE",
        "DROP FUNCTION check_medication_plan() CASCADE",
        "DROP FUNCTION assert_medication_plan(uuid)",
        "DROP FUNCTION medication_treatment_period("
        "medication_plan, medication_plan_version)",
        "DROP FUNCTION lock_medication_patient() CASCADE",
    ):
        op.execute(statement)


def _drop_new_rules() -> None:
    for statement in (
        "DROP FUNCTION fn_check_medication_dose() CASCADE",
        "DROP FUNCTION fn_check_medication_plan() CASCADE",
        "DROP FUNCTION fn_assert_medication_plan(uuid)",
        "DROP FUNCTION fn_medication_treatment_period("
        "medication_plan, medication_plan_version)",
        "DROP FUNCTION fn_lock_medication_circle() CASCADE",
        "DROP FUNCTION fn_check_care_circle() CASCADE",
        "DROP FUNCTION fn_assert_care_circle(uuid)",
        "DROP FUNCTION fn_lock_care_circle() CASCADE",
        "DROP FUNCTION fn_guard_account_care() CASCADE",
    ):
        op.execute(statement)


def _create_child_keys(table: str, column: str, parent: str, keys) -> None:
    """The foreign key and the uniques and indexes of `column` on `table`,
    named for `parent` (new names) or the patient (old names)."""
    new = parent == "care_circle"
    op.create_foreign_key(
        f"fk_{table}_{column}_{parent}", table, parent, [column], ["id"],
        ondelete="CASCADE",
    )
    for kind, old, name, columns, where in keys:
        index_name = name if new else old
        if index_name is None:
            continue
        if kind == "uq":
            op.create_unique_constraint(
                index_name, table, [column] + columns
            )
        elif kind == "ix":
            op.create_index(index_name, table, [column] + columns)
        else:
            op.create_index(
                index_name, table, [column] + columns, unique=True,
                postgresql_where=sa.text(where),
            )


def _move_child(table: str, nullable: bool, keys, *, to_circle: bool):
    """Point `table` at the circle (or back at the patient), moving the
    values through the patient rows."""
    old, new = ("patient_id", "care_circle_id")
    old_parent, new_parent = ("patient", "care_circle")
    if not to_circle:
        old, new = new, old
        old_parent, new_parent = new_parent, old_parent
    op.add_column(table, sa.Column(new, sa.Uuid(), nullable=True))
    if to_circle:
        op.execute(
            f"UPDATE {table} t SET care_circle_id = p.care_circle_id "
            f"FROM patient p WHERE p.id = t.patient_id"
        )
    else:
        op.execute(
            f"UPDATE {table} t SET patient_id = p.id "
            f"FROM patient p WHERE p.care_circle_id = t.care_circle_id"
        )
    if not nullable:
        op.alter_column(table, new, nullable=False)
    if table == "photo":
        op.drop_constraint(op.f("ck_photo_one_owner"), table, type_="check")
    op.drop_constraint(
        f"fk_{table}_{old}_{old_parent}", table, type_="foreignkey"
    )
    op.drop_column(table, old)
    if table == "photo":
        op.create_check_constraint(
            op.f("ck_photo_one_owner"), table,
            _NEW_OWNER if to_circle else _OLD_OWNER,
        )
    _create_child_keys(table, new, new_parent, keys)


def _patient_columns():
    return [
        sa.Column("first_name", sa.Text()),
        sa.Column("last_name", sa.Text()),
        sa.Column("avatar_code", sa.Text()),
        sa.Column("birth_date", sa.Date()),
        sa.Column("city", sa.Text()),
        sa.Column("time_zone", sa.Text()),
        sa.Column("latitude", sa.Double()),
        sa.Column("longitude", sa.Double()),
        sa.Column("blood_type", sa.Text()),
    ]


def upgrade() -> None:
    _drop_old_rules()
    # The patient's columns on the circle.
    op.add_column("care_circle", sa.Column("account_id", sa.Uuid()))
    for column in _patient_columns():
        op.add_column("care_circle", column)
    op.execute(
        "UPDATE care_circle c SET account_id = p.account_id, "
        "first_name = p.first_name, last_name = p.last_name, "
        "avatar_code = p.avatar_code, birth_date = p.birth_date, "
        "city = p.city, time_zone = p.time_zone, latitude = p.latitude, "
        "longitude = p.longitude, blood_type = p.blood_type "
        "FROM patient p WHERE p.care_circle_id = c.id"
    )
    # A linked patient's birth date and city live on the account (the
    # patient's current values win); the circle keeps no copy, and a patient
    # without an account has no name of their own for the circle.
    op.execute(
        "UPDATE account a SET birth_date = p.birth_date, city = p.city "
        "FROM patient p WHERE p.account_id = a.id"
    )
    op.execute(
        "UPDATE care_circle SET first_name = NULL, last_name = NULL, "
        "avatar_code = NULL, birth_date = NULL, city = NULL "
        "WHERE account_id IS NOT NULL"
    )
    # `name` may be empty from here on: allow it before emptying it, or a
    # circle whose patient has no account stops the upgrade.
    op.alter_column("care_circle", "name", nullable=True)
    op.drop_constraint(
        op.f("ck_care_circle_name"), "care_circle", type_="check"
    )
    op.execute("UPDATE care_circle SET name = NULL WHERE account_id IS NULL")
    op.alter_column("care_circle", "time_zone", nullable=False)
    for name, rule in _CIRCLE_CHECKS:
        op.create_check_constraint(
            op.f(f"ck_care_circle_{name}"), "care_circle", rule
        )
    op.create_foreign_key(
        op.f("fk_care_circle_account_id_account"), "care_circle", "account",
        ["account_id"], ["id"], ondelete="RESTRICT",
    )
    op.create_unique_constraint(
        op.f("uq_care_circle_account_id"), "care_circle", ["account_id"]
    )
    # Every table that pointed at the patient points at the circle.
    for table, nullable, keys in _CHILDREN:
        _move_child(table, nullable, keys, to_circle=True)
    op.drop_table("patient")
    op.execute(
        "ALTER TABLE care_circle_manager RENAME CONSTRAINT "
        "uq_care_circle_manager_care_circle_id TO "
        "uq_care_circle_manager_care_circle_id_account_id"
    )
    op.execute(_sql("0037_rules.sql"))


def _old_rules() -> None:
    """The rules as migration 0036 left them: the core rules of 0001 with
    0003's lock, and the medication rules of 0007 as patched since."""
    m0003 = _migration("0003_serialize_patient_profile.py")
    m0034 = _migration("0034_medication_rules_in_patient_zone.py")
    m0036 = _migration("0036_medication_names.py")
    op.execute(_sql("0001_core_rules.sql"))
    op.execute(
        m0003._GUARD.replace(
            "LOCK_ACCOUNT_CONDITION", "NEW.account_id IS NOT NULL"
        )
    )
    for name in ("lock_medication_patient", "assert_medication_plan",
                 "check_medication_plan"):
        op.execute(m0034.rule_text(name, patient_zone=True))
    for name in ("medication_treatment_period", "check_medication_dose"):
        op.execute(m0036.rule_text(name, stopped=True))
    rules = _sql("0007_medication_rules.sql")
    for statement in rules.split(";"):
        statement = "\n".join(
            line for line in statement.splitlines()
            if not line.lstrip().startswith("--")
        ).strip()
        if statement.startswith("CREATE TRIGGER") or (
            statement.startswith("CREATE CONSTRAINT TRIGGER")
            and "check_medication_dose_valid" not in statement
        ):
            op.execute(statement)
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
    op.execute(
        "CREATE CONSTRAINT TRIGGER check_medication_dose_valid "
        "AFTER INSERT OR UPDATE OF schedule_id, scheduled_on "
        "ON medication_dose_record DEFERRABLE INITIALLY DEFERRED "
        "FOR EACH ROW EXECUTE FUNCTION check_medication_dose()"
    )


def downgrade() -> None:
    _drop_new_rules()
    op.create_table(
        "patient",
        sa.Column(
            "id", sa.Uuid(), server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("care_circle_id", sa.Uuid(), nullable=False),
        sa.Column("account_id", sa.Uuid()),
        *_patient_columns(),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_patient")),
        sa.ForeignKeyConstraint(
            ["care_circle_id"], ["care_circle.id"], ondelete="CASCADE",
            name=op.f("fk_patient_care_circle_id_care_circle"),
        ),
        sa.ForeignKeyConstraint(
            ["account_id"], ["account.id"], ondelete="RESTRICT",
            name=op.f("fk_patient_account_id_account"),
        ),
        sa.UniqueConstraint(
            "care_circle_id", name=op.f("uq_patient_care_circle_id")
        ),
        sa.UniqueConstraint("account_id", name=op.f("uq_patient_account_id")),
    )
    op.execute(
        "INSERT INTO patient (care_circle_id, account_id, first_name, "
        "last_name, avatar_code, birth_date, city, time_zone, latitude, "
        "longitude, blood_type) "
        "SELECT c.id, c.account_id, c.first_name, c.last_name, "
        "c.avatar_code, COALESCE(c.birth_date, a.birth_date), "
        "COALESCE(c.city, a.city), c.time_zone, c.latitude, c.longitude, "
        "c.blood_type FROM care_circle c "
        "LEFT JOIN account a ON a.id = c.account_id"
    )
    for column, nullable in (
        ("birth_date", False), ("city", False), ("time_zone", False),
    ):
        op.alter_column("patient", column, nullable=nullable)
    m0035 = _migration("0035_database_limits_match_the_api.py")
    for name, rule in (
        ("name_source", m0035._NAME_SOURCE_NEW),
        ("city", "length(btrim(city)) BETWEEN 1 AND 60"),
        ("time_zone", "length(btrim(time_zone)) BETWEEN 1 AND 64"),
        ("birth_date", "birth_date >= DATE '1900-01-01'"),
        ("latitude", "latitude BETWEEN -90 AND 90"),
        ("longitude", "longitude BETWEEN -180 AND 180"),
        ("blood_type", f"blood_type IN {_BLOOD}"),
        ("avatar_code", f"avatar_code IS NULL OR avatar_code IN {_AVATARS}"),
    ):
        op.create_check_constraint(op.f(f"ck_patient_{name}"), "patient", rule)
    for table, nullable, keys in reversed(_CHILDREN):
        _move_child(table, nullable, keys, to_circle=False)
    op.execute(
        "ALTER TABLE care_circle_manager RENAME CONSTRAINT "
        "uq_care_circle_manager_care_circle_id_account_id TO "
        "uq_care_circle_manager_care_circle_id"
    )
    # The merged circle's checks go first: `account_source` allows no name
    # on a circle without an account, and the old circle needs one.
    for name, _ in reversed(_CIRCLE_CHECKS):
        op.drop_constraint(
            op.f(f"ck_care_circle_{name}"), "care_circle", type_="check"
        )
    op.execute(
        "UPDATE care_circle SET name = 'دائرة ' || first_name "
        "WHERE name IS NULL"
    )
    op.drop_constraint(
        op.f("uq_care_circle_account_id"), "care_circle", type_="unique"
    )
    op.drop_constraint(
        op.f("fk_care_circle_account_id_account"), "care_circle",
        type_="foreignkey",
    )
    for column in reversed(_patient_columns()):
        op.drop_column("care_circle", column.name)
    op.drop_column("care_circle", "account_id")
    op.alter_column("care_circle", "name", nullable=False)
    op.create_check_constraint(
        op.f("ck_care_circle_name"), "care_circle",
        "length(btrim(name)) BETWEEN 1 AND 60",
    )
    _old_rules()
