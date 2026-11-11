"""The medication rules read the patient's own time zone.

Two rules of the database turned the moment a medicine was stopped into a
calendar day with the fixed zone Asia/Riyadh: the one that keeps two
medicines of one name from overlapping, and the one that checks a dose's
date is on its schedule. The server has read `patient.time_zone` since
migration 0036, so for a patient elsewhere the two sides could disagree
about the last day of a stopped medicine. Both rules now read the zone of
the medicine's patient.

Revision ID: 0034
Revises: 0036
"""
import importlib.util
from pathlib import Path

from alembic import op

revision = "0034"
down_revision = "0033"
branch_labels = None
depends_on = None


def _migration(name: str):
    """An earlier migration module, for the text of the rules it left."""
    path = Path(__file__).with_name(name)
    spec = importlib.util.spec_from_file_location(name[:-3], path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_M0022 = _migration("0022_medication_monthly_schedules.py")
_M0026 = _migration("0026_medication_interval_schedules.py")

_RIYADH_STOP_DAY = (
    "(plan_row.discontinued_at AT TIME ZONE 'Asia/Riyadh')::date + 1"
)
_PATIENT_STOP_DAY = (
    "(plan_row.discontinued_at AT TIME ZONE (\n"
    "                SELECT time_zone FROM patient\n"
    "                WHERE id = plan_row.patient_id\n"
    "            ))::date + 1"
)
_PLAN_JOIN = "        JOIN medication_plan p ON p.id = v.medication_plan_id\n"
_PLAN_AND_PATIENT_JOIN = _PLAN_JOIN + (
    "        JOIN patient pt ON pt.id = p.patient_id\n"
)
_RIYADH_DOSE_MOMENT = (
    "                  AT TIME ZONE 'Asia/Riyadh' < p.discontinued_at\n"
)
_PATIENT_DOSE_MOMENT = (
    "                  AT TIME ZONE pt.time_zone < p.discontinued_at\n"
)

# Migration 0008's change to the treatment period (a cancelled version runs
# on no day), which 0022 and 0026 did not touch.
_AFTER_0008_PERIOD = (
    (
        "IF starts_on >= ends_on THEN",
        "IF version_row.cancelled_at IS NOT NULL THEN "
        "RETURN 'empty'::daterange; END IF;\n"
        "    IF starts_on >= ends_on THEN",
    ),
)

ZONE_CHANGES = {
    "medication_treatment_period": ((_RIYADH_STOP_DAY, _PATIENT_STOP_DAY),),
    "check_medication_dose": (
        (_PLAN_JOIN, _PLAN_AND_PATIENT_JOIN),
        (_RIYADH_DOSE_MOMENT, _PATIENT_DOSE_MOMENT),
    ),
}


def rule_text(name: str, *, patient_zone: bool) -> str:
    """One rule as migration 0026 left it, with the zone change or
    without it: the text other migrations build on."""
    source = Path(__file__).with_name("0007_medication_rules.sql")
    rules = source.read_text(encoding="utf-8")
    start = rules.index(f"CREATE FUNCTION {name}(")
    end = rules.index("$$;", start) + 3
    statement = rules[start:end].replace(
        "CREATE FUNCTION", "CREATE OR REPLACE FUNCTION", 1
    )
    changes = ()
    if name == "medication_treatment_period":
        changes += _AFTER_0008_PERIOD
    if name in _M0022._AFTER_0008:
        changes += _M0022._AFTER_0008[name]
        changes += _M0022._MONTHLY_CHANGES[name]
        changes += _M0026._INTERVAL_CHANGES[name]
    if patient_zone:
        changes += ZONE_CHANGES.get(name, ())
    for old, new in changes:
        if statement.count(old) != 1:
            raise RuntimeError(f"Unexpected source for medication rule {name}")
        statement = statement.replace(old, new)
    return statement


def upgrade() -> None:
    for name in ZONE_CHANGES:
        op.execute(rule_text(name, patient_zone=True))


def downgrade() -> None:
    for name in ZONE_CHANGES:
        op.execute(rule_text(name, patient_zone=False))
