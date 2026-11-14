"""More chronic conditions, and the medicine allergies split and widened.

The chronic list gains the ones Saudi studies find most often in older
people (high cholesterol, stroke, dementia…). «الأسبرين ومضادات الالتهاب»
was one choice for two different allergies: it becomes `aspirin` and
`nsaids`, and a patient who had it gets both, because under-reporting an
allergy is the unsafe side. `quinolones` and `opioids` join the list.

Revision ID: 0053
Revises: 0052
"""
from alembic import op

from app.models.medical import CONDITION_CODES, MEDICATION_ALLERGY_CODES

revision = "0053"
down_revision = "0052"
branch_labels = None
depends_on = None

_OLD_CONDITIONS = (
    "diabetes", "hypertension", "heart", "asthma", "kidney", "thyroid",
    "other",
)
_OLD_MEDICATIONS = (
    "penicillin", "sulfa", "cephalosporins", "aspirin_nsaids",
    "contrast_media", "anesthesia", "other",
)
_NEW_CONDITIONS = tuple(c for c in CONDITION_CODES if c not in _OLD_CONDITIONS)
_FOODS = (
    "milk", "eggs", "fish", "shellfish", "tree_nuts", "peanuts", "wheat",
    "soy", "sesame", "other",
)


def _sql(codes) -> str:
    return ", ".join(f"'{code}'" for code in codes)


def _conditions(codes) -> None:
    name = op.f("ck_patient_condition_code")
    op.drop_constraint(name, "patient_condition", type_="check")
    op.create_check_constraint(
        name, "patient_condition", f"code IN ({_sql(codes)})"
    )


def _allergies(medications) -> None:
    name = op.f("ck_patient_allergy_kind_code")
    op.drop_constraint(name, "patient_allergy", type_="check")
    op.create_check_constraint(
        name, "patient_allergy",
        f"(kind = 'medication' AND code IN ({_sql(medications)})) OR "
        f"(kind = 'food' AND code IN ({_sql(_FOODS)}))",
    )


def upgrade() -> None:
    _conditions(CONDITION_CODES)
    _allergies(tuple(MEDICATION_ALLERGY_CODES) + ("aspirin_nsaids",))
    # Both halves of the old pair, then the pair itself goes.
    op.execute(
        "INSERT INTO patient_allergy (care_circle_id, kind, code) "
        "SELECT care_circle_id, 'medication', 'aspirin' FROM patient_allergy "
        "WHERE kind = 'medication' AND code = 'aspirin_nsaids'"
    )
    op.execute(
        "UPDATE patient_allergy SET code = 'nsaids' "
        "WHERE kind = 'medication' AND code = 'aspirin_nsaids'"
    )
    _allergies(MEDICATION_ALLERGY_CODES)


def downgrade() -> None:
    """Fold the two halves back into one choice, and drop what is new."""
    op.execute(
        "DELETE FROM patient_allergy WHERE kind = 'medication' "
        "AND code = 'aspirin'"
    )
    op.execute(
        "UPDATE patient_allergy SET code = 'aspirin_nsaids' "
        "WHERE kind = 'medication' AND code = 'nsaids'"
    )
    op.execute(
        "DELETE FROM patient_allergy WHERE kind = 'medication' "
        f"AND code IN ({_sql(('quinolones', 'opioids'))})"
    )
    op.execute(
        "DELETE FROM patient_condition WHERE code IN "
        f"({_sql(_NEW_CONDITIONS)})"
    )
    _allergies(_OLD_MEDICATIONS)
    _conditions(_OLD_CONDITIONS)
