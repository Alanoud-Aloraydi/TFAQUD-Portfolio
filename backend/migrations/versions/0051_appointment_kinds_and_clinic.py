"""More kinds of visit, and the clinic as optional free text.

The kind list grows from five to twenty (`app/appointments/kinds.py`).
`specialty` was a clinic chosen from a list and saved as its English code
(«diabetes»); it is now the clinic or doctor as typed, and optional, so the
codes become their Arabic names.

Revision ID: 0051
Revises: 0050
"""
from alembic import op

from app.appointments.kinds import kinds_sql

revision = "0051"
down_revision = "0050"
branch_labels = None
depends_on = None

_OLD_KINDS = "'follow_up', 'test', 'imaging', 'remote', 'other'"
_OLD_CODES = {
    "internal": "عيادة الباطنة",
    "diabetes": "عيادة السكري",
    "cardiology": "عيادة القلب",
    "eyes": "عيادة العيون",
    "dental": "عيادة الأسنان",
    "neurology": "عيادة الأعصاب",
}


def upgrade() -> None:
    op.drop_constraint(
        op.f("ck_appointment_kind"), "appointment", type_="check"
    )
    op.create_check_constraint(
        op.f("ck_appointment_kind"), "appointment", f"kind IN ({kinds_sql()})"
    )
    for code, name in _OLD_CODES.items():
        op.execute(
            f"UPDATE appointment SET specialty = '{name}' "
            f"WHERE specialty = '{code}'"
        )
    op.drop_constraint(
        op.f("ck_appointment_specialty"), "appointment", type_="check"
    )
    op.alter_column("appointment", "specialty", nullable=True)
    op.create_check_constraint(
        op.f("ck_appointment_specialty"), "appointment",
        "specialty IS NULL OR (length(btrim(specialty)) > 0 AND "
        "char_length(specialty) <= 80)",
    )


def downgrade() -> None:
    """Fold the new kinds into «أخرى» and give every visit a clinic."""
    op.execute(
        "UPDATE appointment SET other_text = coalesce(other_text, kind), "
        f"kind = 'other' WHERE kind NOT IN ({_OLD_KINDS})"
    )
    op.execute(
        "UPDATE appointment SET specialty = 'أخرى' "
        "WHERE specialty IS NULL"
    )
    op.drop_constraint(
        op.f("ck_appointment_specialty"), "appointment", type_="check"
    )
    op.alter_column("appointment", "specialty", nullable=False)
    op.create_check_constraint(
        op.f("ck_appointment_specialty"), "appointment",
        "length(btrim(specialty)) > 0 AND char_length(specialty) <= 80",
    )
    op.drop_constraint(
        op.f("ck_appointment_kind"), "appointment", type_="check"
    )
    op.create_check_constraint(
        op.f("ck_appointment_kind"), "appointment", f"kind IN ({_OLD_KINDS})"
    )
