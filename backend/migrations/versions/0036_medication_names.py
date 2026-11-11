"""One word for a plan the family stopped, and one text type.

A medicine was "discontinued" and a measurement plan "stopped": both are
`stopped_at` now, each with who stopped it (`stopped_by_account_id`; the
measurement plan never recorded that). The medication tables kept their
texts as varchar(n) while every other table uses text with a check: they
use text with the same limits now. The medication indexes are named after
the table and every column they cover, as the rest of the schema is.

The two rules that read the stop moment are reinstalled with the new name.

Revision ID: 0036
Revises: 0035
"""
import importlib.util
from pathlib import Path

from alembic import op
import sqlalchemy as sa

revision = "0036"
down_revision = "0035"
branch_labels = None
depends_on = None


def _migration(name: str):
    path = Path(__file__).with_name(name)
    spec = importlib.util.spec_from_file_location(name[:-3], path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_M0034 = _migration("0034_medication_rules_in_patient_zone.py")

STOP_RENAMES = (("discontinued_at", "stopped_at"),)
_PLAN = "medication_plan"
_VERSION = "medication_plan_version"
_SCHEDULE = "medication_schedule"
_DOSE = "medication_dose_record"

# (table, column, varchar length, new check name) for the texts that were
# varchar(n): the same limit as a check.
_TEXTS = (
    (_VERSION, "reason_for_use", 100, "reason_for_use_length"),
    (_VERSION, "instructions", 250, "instructions_length"),
    (_SCHEDULE, "instructions", 250, "instructions_length"),
    (_DOSE, "skip_reason_note", 250, "skip_reason_note_length"),
)
_INDEX_RENAMES = (
    (
        "uq_medication_plan_version_effective_from_on",
        "uq_medication_plan_version_medication_plan_id_effective_from_on",
    ),
    (
        "uq_medication_plan_version_open",
        "uq_medication_plan_version_medication_plan_id_open",
    ),
)
_UNIQUE_RENAMES = (
    (
        _VERSION,
        "uq_medication_plan_version_medication_plan_id",
        "uq_medication_plan_version_medication_plan_id_version_number",
    ),
    (
        _DOSE,
        "uq_medication_dose_record_schedule_id",
        "uq_medication_dose_record_schedule_id_scheduled_on",
    ),
)


def rule_text(name: str, *, stopped: bool) -> str:
    """One rule as 0034 left it, with `discontinued_at` renamed or not."""
    statement = _M0034.rule_text(name, patient_zone=True)
    if stopped:
        for old, new in STOP_RENAMES:
            statement = statement.replace(old, new)
    return statement


def _rename_constraint(table: str, old: str, new: str) -> None:
    op.execute(
        f"ALTER TABLE {table} RENAME CONSTRAINT {old} TO {new}"
    )


def upgrade() -> None:
    # The medicine's stop: the same words as a measurement plan's.
    op.alter_column(_PLAN, "discontinued_at", new_column_name="stopped_at")
    op.alter_column(
        _PLAN, "discontinued_by_account_id",
        new_column_name="stopped_by_account_id",
    )
    _rename_constraint(
        _PLAN, "ck_medication_plan_discontinuation_state",
        "ck_medication_plan_stopped_state",
    )
    _rename_constraint(
        _PLAN, "fk_medication_plan_discontinued_by_account_id_account",
        "fk_medication_plan_stopped_by_account_id_account",
    )
    op.execute(
        "ALTER INDEX ix_medication_plan_discontinued_by_account_id "
        "RENAME TO ix_medication_plan_stopped_by_account_id"
    )
    for name in ("medication_treatment_period", "check_medication_dose"):
        op.execute(rule_text(name, stopped=True))
    # Who stopped a measurement plan, as for a medicine.
    op.add_column(
        "measurement_plan", sa.Column("stopped_by_account_id", sa.Uuid())
    )
    op.create_foreign_key(
        op.f("fk_measurement_plan_stopped_by_account_id_account"),
        "measurement_plan", "account", ["stopped_by_account_id"], ["id"],
        ondelete="SET NULL",
    )
    op.create_check_constraint(
        op.f("ck_measurement_plan_stopped_state"), "measurement_plan",
        "stopped_at IS NOT NULL OR stopped_by_account_id IS NULL",
    )
    op.create_index(
        op.f("ix_measurement_plan_stopped_by_account_id"),
        "measurement_plan", ["stopped_by_account_id"],
    )
    # Text with a check instead of varchar(n).
    op.alter_column(_VERSION, "name", type_=sa.Text())
    op.drop_constraint(
        op.f("ck_medication_plan_version_name_nonblank"), _VERSION,
        type_="check",
    )
    op.create_check_constraint(
        op.f("ck_medication_plan_version_name"), _VERSION,
        "length(btrim(name)) BETWEEN 1 AND 50",
    )
    for table, column, length, check in _TEXTS:
        op.alter_column(table, column, type_=sa.Text())
        op.create_check_constraint(
            op.f(f"ck_{table}_{check}"), table,
            f"{column} IS NULL OR char_length({column}) <= {length}",
        )
    op.alter_column(_DOSE, "skip_reason_code", type_=sa.Text())
    # Indexes and uniques named after every column they cover.
    for old, new in _INDEX_RENAMES:
        op.execute(f"ALTER INDEX {old} RENAME TO {new}")
    for table, old, new in _UNIQUE_RENAMES:
        _rename_constraint(table, old, new)


def downgrade() -> None:
    for table, old, new in _UNIQUE_RENAMES:
        _rename_constraint(table, new, old)
    for old, new in _INDEX_RENAMES:
        op.execute(f"ALTER INDEX {new} RENAME TO {old}")
    op.alter_column(_DOSE, "skip_reason_code", type_=sa.String(40))
    for table, column, length, check in reversed(_TEXTS):
        op.drop_constraint(op.f(f"ck_{table}_{check}"), table, type_="check")
        op.alter_column(table, column, type_=sa.String(length))
    op.drop_constraint(
        op.f("ck_medication_plan_version_name"), _VERSION, type_="check"
    )
    op.create_check_constraint(
        op.f("ck_medication_plan_version_name_nonblank"), _VERSION,
        "length(btrim(name)) > 0",
    )
    op.alter_column(_VERSION, "name", type_=sa.String(50))
    op.drop_index(
        op.f("ix_measurement_plan_stopped_by_account_id"),
        table_name="measurement_plan",
    )
    op.drop_constraint(
        op.f("ck_measurement_plan_stopped_state"), "measurement_plan",
        type_="check",
    )
    op.drop_constraint(
        op.f("fk_measurement_plan_stopped_by_account_id_account"),
        "measurement_plan", type_="foreignkey",
    )
    op.drop_column("measurement_plan", "stopped_by_account_id")
    for name in ("medication_treatment_period", "check_medication_dose"):
        op.execute(rule_text(name, stopped=False))
    op.execute(
        "ALTER INDEX ix_medication_plan_stopped_by_account_id "
        "RENAME TO ix_medication_plan_discontinued_by_account_id"
    )
    _rename_constraint(
        _PLAN, "fk_medication_plan_stopped_by_account_id_account",
        "fk_medication_plan_discontinued_by_account_id_account",
    )
    _rename_constraint(
        _PLAN, "ck_medication_plan_stopped_state",
        "ck_medication_plan_discontinuation_state",
    )
    op.alter_column(
        _PLAN, "stopped_by_account_id",
        new_column_name="discontinued_by_account_id",
    )
    op.alter_column(_PLAN, "stopped_at", new_column_name="discontinued_at")
