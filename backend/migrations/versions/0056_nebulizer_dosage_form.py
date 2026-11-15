"""«بخار»: the solution a nebulizer turns into mist, a form of its own.

It was being written as «شراب» or «بخاخ», neither of which is what the
patient is handed. Its dose is in millilitres, like any other liquid, so
only the form's own list grows here.

Revision ID: 0056
Revises: 0055
"""
from alembic import op

revision = "0056"
down_revision = "0055"
branch_labels = None
depends_on = None

_WITHOUT = "'tablet', 'capsule', 'liquid', 'drops', 'inhaler', 'injection'"
_WITH = (
    "'tablet', 'capsule', 'liquid', 'drops', "
    "'inhaler', 'nebulizer', 'injection'"
)


def _forms(codes: str) -> None:
    name = op.f("ck_medication_plan_version_dosage_form")
    op.drop_constraint(name, "medication_plan_version", type_="check")
    op.create_check_constraint(
        name, "medication_plan_version", f"dosage_form IN ({codes})"
    )


def upgrade() -> None:
    _forms(_WITH)


def downgrade() -> None:
    # A plan already written as «بخار» has no older form to fall back to,
    # and a liquid is the closest thing the patient actually holds.
    op.execute(
        "UPDATE medication_plan_version SET dosage_form = 'liquid' "
        "WHERE dosage_form = 'nebulizer'"
    )
    _forms(_WITHOUT)
