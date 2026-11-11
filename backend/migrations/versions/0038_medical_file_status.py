"""«No conditions» and «no allergies» are a status, not a row.

The medical file kept one row with the code `none` to say the question was
answered with nothing, beside the rows of real conditions and allergies.
That row was a status in disguise, and nothing stopped it from standing
next to real codes. The circle now carries the answer itself:
`conditions_status` and `allergies_status`, `listed` or `none`, and null
while the question was not asked. The code lists lose `none`.

Revision ID: 0038
Revises: 0037
"""
from alembic import op
import sqlalchemy as sa

revision = "0038"
down_revision = "0037"
branch_labels = None
depends_on = None

_STATUS = "IN ('none', 'listed')"
_CONDITIONS = (
    "('diabetes', 'hypertension', 'heart', 'asthma', 'kidney', "
    "'thyroid', 'other')"
)
_MEDICATION = (
    "('penicillin', 'sulfa', 'cephalosporins', 'aspirin_nsaids', "
    "'contrast_media', 'anesthesia', 'other')"
)
_FOOD = (
    "('milk', 'eggs', 'fish', 'shellfish', 'tree_nuts', 'peanuts', "
    "'wheat', 'soy', 'sesame', 'other')"
)


def upgrade() -> None:
    for column in ("conditions_status", "allergies_status"):
        op.add_column("care_circle", sa.Column(column, sa.Text()))
        op.create_check_constraint(
            op.f(f"ck_care_circle_{column}"), "care_circle",
            f"{column} IS NULL OR {column} {_STATUS}",
        )
    # The answer each file gave: «none» where the sentinel row was, «listed»
    # where real rows are.
    op.execute(
        "UPDATE care_circle c SET conditions_status = CASE "
        "WHEN EXISTS (SELECT 1 FROM patient_condition p "
        "WHERE p.care_circle_id = c.id AND p.code = 'none') THEN 'none' "
        "WHEN EXISTS (SELECT 1 FROM patient_condition p "
        "WHERE p.care_circle_id = c.id) THEN 'listed' END"
    )
    op.execute(
        "UPDATE care_circle c SET allergies_status = CASE "
        "WHEN EXISTS (SELECT 1 FROM patient_allergy p "
        "WHERE p.care_circle_id = c.id AND p.kind = 'none') THEN 'none' "
        "WHEN EXISTS (SELECT 1 FROM patient_allergy p "
        "WHERE p.care_circle_id = c.id) THEN 'listed' END"
    )
    op.execute("DELETE FROM patient_condition WHERE code = 'none'")
    op.execute("DELETE FROM patient_allergy WHERE kind = 'none'")
    op.drop_constraint(
        op.f("ck_patient_condition_code"), "patient_condition", type_="check"
    )
    op.create_check_constraint(
        op.f("ck_patient_condition_code"), "patient_condition",
        f"code IN {_CONDITIONS}",
    )
    op.drop_constraint(
        op.f("ck_patient_allergy_kind_code"), "patient_allergy", type_="check"
    )
    op.create_check_constraint(
        op.f("ck_patient_allergy_kind_code"), "patient_allergy",
        f"(kind = 'medication' AND code IN {_MEDICATION}) OR "
        f"(kind = 'food' AND code IN {_FOOD})",
    )


def downgrade() -> None:
    op.drop_constraint(
        op.f("ck_patient_allergy_kind_code"), "patient_allergy", type_="check"
    )
    op.create_check_constraint(
        op.f("ck_patient_allergy_kind_code"), "patient_allergy",
        "(kind = 'none' AND code = 'none') OR "
        f"(kind = 'medication' AND code IN {_MEDICATION}) OR "
        f"(kind = 'food' AND code IN {_FOOD})",
    )
    op.drop_constraint(
        op.f("ck_patient_condition_code"), "patient_condition", type_="check"
    )
    op.create_check_constraint(
        op.f("ck_patient_condition_code"), "patient_condition",
        "code IN ('none', 'diabetes', 'hypertension', 'heart', 'asthma', "
        "'kidney', 'thyroid', 'other')",
    )
    op.execute(
        "INSERT INTO patient_condition (care_circle_id, code) "
        "SELECT id, 'none' FROM care_circle WHERE conditions_status = 'none'"
    )
    op.execute(
        "INSERT INTO patient_allergy (care_circle_id, kind, code) "
        "SELECT id, 'none', 'none' FROM care_circle "
        "WHERE allergies_status = 'none'"
    )
    for column in ("allergies_status", "conditions_status"):
        op.drop_constraint(
            op.f(f"ck_care_circle_{column}"), "care_circle", type_="check"
        )
        op.drop_column("care_circle", column)
