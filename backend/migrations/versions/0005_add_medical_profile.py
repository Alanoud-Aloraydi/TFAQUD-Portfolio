"""Add the medical profile: blood type, conditions, allergies, contacts."""

from alembic import op
import sqlalchemy as sa

revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None

# The lists below are copied here on purpose. A migration describes the
# database as it was when it was written, so it must not import the models,
# which can change later.
_BLOOD_TYPES = "('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')"
_CONDITIONS = (
    "('none', 'diabetes', 'hypertension', 'heart', 'asthma', 'kidney', "
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
_RELATIONS = "('son', 'daughter', 'husband', 'wife', 'other')"

_OTHER_TEXT = (
    "(code = 'other' AND other_text IS NOT NULL "
    "AND length(btrim(other_text)) BETWEEN 1 AND 100) OR "
    "(code <> 'other' AND other_text IS NULL)"
)


def _patient_id():
    """Medical rows belong to the patient and disappear with the patient."""
    return sa.Column(
        "patient_id",
        sa.Uuid(),
        sa.ForeignKey("patient.id", ondelete="CASCADE"),
        nullable=False,
    )


def _id():
    return sa.Column(
        "id",
        sa.Uuid(),
        server_default=sa.text("gen_random_uuid()"),
        primary_key=True,
    )


def upgrade():
    """Add medical data beside the patient, without changing care rules."""
    op.add_column("patient", sa.Column("blood_type", sa.Text()))
    op.create_check_constraint(
        "blood_type", "patient", f"blood_type IN {_BLOOD_TYPES}"
    )

    op.create_table(
        "patient_condition",
        _id(),
        _patient_id(),
        sa.Column("code", sa.Text(), nullable=False),
        sa.Column("other_text", sa.Text()),
        sa.UniqueConstraint("patient_id", "code"),
        sa.CheckConstraint(f"code IN {_CONDITIONS}", name="code"),
        sa.CheckConstraint(_OTHER_TEXT, name="other_text"),
    )

    op.create_table(
        "patient_allergy",
        _id(),
        _patient_id(),
        sa.Column("kind", sa.Text(), nullable=False),
        sa.Column("code", sa.Text(), nullable=False),
        sa.Column("other_text", sa.Text()),
        sa.UniqueConstraint("patient_id", "kind", "code"),
        sa.CheckConstraint(
            "(kind = 'none' AND code = 'none') OR "
            f"(kind = 'medication' AND code IN {_MEDICATION}) OR "
            f"(kind = 'food' AND code IN {_FOOD})",
            name="kind_code",
        ),
        sa.CheckConstraint(_OTHER_TEXT, name="other_text"),
    )

    op.create_table(
        "emergency_contact",
        _id(),
        _patient_id(),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("relation", sa.Text(), nullable=False),
        sa.Column("phone_number", sa.Text(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.UniqueConstraint("patient_id", "phone_number"),
        sa.CheckConstraint(
            "length(btrim(name)) BETWEEN 1 AND 50", name="name"
        ),
        sa.CheckConstraint(f"relation IN {_RELATIONS}", name="relation"),
        sa.CheckConstraint(
            "phone_number ~ '^\\+[1-9][0-9]{1,14}$'", name="phone_format"
        ),
    )


def downgrade():
    """Remove only the medical data introduced here."""
    op.drop_table("emergency_contact")
    op.drop_table("patient_allergy")
    op.drop_table("patient_condition")
    op.drop_constraint("blood_type", "patient", type_="check")
    op.drop_column("patient", "blood_type")
