"""Store private photos and selected avatar codes.

Revision ID: 0016
Revises: 0015
"""

from alembic import op
import sqlalchemy as sa

revision = "0016"
down_revision = "0015"
branch_labels = None
depends_on = None

AVATAR_CODES = (
    "w1_1", "w1_3", "w6_1", "w6_3", "w7_1", "w7_3",
    "m1_1", "m1_3", "m2_1", "m2_3", "m6_1", "m6_3",
)


def upgrade() -> None:
    """Add one private image per owner and bounded avatar choices."""
    choices = ", ".join(f"'{code}'" for code in AVATAR_CODES)
    for table in ("account", "patient"):
        op.add_column(table, sa.Column("avatar_code", sa.Text()))
        op.create_check_constraint(
            op.f(f"ck_{table}_avatar_code"), table,
            f"avatar_code IS NULL OR avatar_code IN ({choices})",
        )
    op.create_table(
        "photo",
        sa.Column("id", sa.Uuid(), server_default=sa.text(
            "gen_random_uuid()"), nullable=False),
        sa.Column("account_id", sa.Uuid()),
        sa.Column("patient_id", sa.Uuid()),
        sa.Column("medication_plan_id", sa.Uuid()),
        sa.Column("data", sa.LargeBinary(), nullable=False),
        sa.CheckConstraint(
            "num_nonnulls(account_id, patient_id, medication_plan_id) = 1",
            name=op.f("ck_photo_one_owner"),
        ),
        sa.CheckConstraint(
            "octet_length(data) BETWEEN 1 AND 4194304",
            name=op.f("ck_photo_bounded_data"),
        ),
        sa.ForeignKeyConstraint(
            ["account_id"], ["account.id"], ondelete="CASCADE",
            name=op.f("fk_photo_account_id_account"),
        ),
        sa.ForeignKeyConstraint(
            ["patient_id"], ["patient.id"], ondelete="CASCADE",
            name=op.f("fk_photo_patient_id_patient"),
        ),
        sa.ForeignKeyConstraint(
            ["medication_plan_id"], ["medication_plan.id"],
            ondelete="CASCADE",
            name=op.f("fk_photo_medication_plan_id_medication_plan"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_photo")),
        sa.UniqueConstraint("account_id", name=op.f("uq_photo_account_id")),
        sa.UniqueConstraint("patient_id", name=op.f("uq_photo_patient_id")),
        sa.UniqueConstraint(
            "medication_plan_id",
            name=op.f("uq_photo_medication_plan_id"),
        ),
    )


def downgrade() -> None:
    """Remove stored images and avatar choices."""
    op.drop_table("photo")
    for table in ("patient", "account"):
        op.drop_constraint(op.f(f"ck_{table}_avatar_code"), table)
        op.drop_column(table, "avatar_code")
