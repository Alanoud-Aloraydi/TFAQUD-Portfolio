"""Save one target and allow one active plan per measurement kind.

Revision ID: 0015
Revises: 0014
"""

from alembic import op
import sqlalchemy as sa

revision = "0015"
down_revision = "0014"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create bounded targets and enforce active-plan uniqueness."""
    op.create_table(
        "measurement_target",
        sa.Column("id", sa.Uuid(), server_default=sa.text(
            "gen_random_uuid()"), nullable=False),
        sa.Column("patient_id", sa.Uuid(), nullable=False),
        sa.Column("kind", sa.Text(), nullable=False),
        sa.Column("glucose_low", sa.SmallInteger()),
        sa.Column("glucose_high", sa.SmallInteger()),
        sa.Column("systolic_limit", sa.SmallInteger()),
        sa.Column("diastolic_limit", sa.SmallInteger()),
        sa.CheckConstraint(
            "kind IN ('glucose', 'bp')",
            name=op.f("ck_measurement_target_kind"),
        ),
        sa.CheckConstraint(
            "(kind = 'glucose' AND glucose_low IS NOT NULL "
            "AND glucose_high IS NOT NULL AND glucose_low BETWEEN 1 AND 999 "
            "AND glucose_high BETWEEN 1 AND 999 "
            "AND glucose_low < glucose_high AND systolic_limit IS NULL "
            "AND diastolic_limit IS NULL) OR "
            "(kind = 'bp' AND systolic_limit IS NOT NULL "
            "AND diastolic_limit IS NOT NULL "
            "AND systolic_limit BETWEEN 1 AND 999 "
            "AND diastolic_limit BETWEEN 1 AND 999 "
            "AND systolic_limit > diastolic_limit AND glucose_low IS NULL "
            "AND glucose_high IS NULL)",
            name=op.f("ck_measurement_target_target_shape"),
        ),
        sa.ForeignKeyConstraint(
            ["patient_id"], ["patient.id"], ondelete="CASCADE",
            name=op.f("fk_measurement_target_patient_id_patient"),
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_measurement_target")),
        sa.UniqueConstraint(
            "patient_id", "kind",
            name=op.f("uq_measurement_target_patient_id"),
        ),
    )
    op.execute(
        "INSERT INTO measurement_target "
        "(patient_id, kind, glucose_low, glucose_high, "
        "systolic_limit, diastolic_limit) "
        "SELECT DISTINCT ON (p.patient_id, p.kind) p.patient_id, p.kind, "
        "v.glucose_low, v.glucose_high, v.systolic_limit, "
        "v.diastolic_limit FROM measurement_plan p "
        "JOIN measurement_plan_version v ON v.plan_id = p.id "
        "ORDER BY p.patient_id, p.kind, p.created_at DESC, v.number DESC"
    )
    op.create_index(
        "uq_measurement_plan_active_kind", "measurement_plan",
        ["patient_id", "kind"], unique=True,
        postgresql_where=sa.text("stopped_at IS NULL"),
    )


def downgrade() -> None:
    """Remove targets and the active-plan uniqueness rule."""
    op.drop_index("uq_measurement_plan_active_kind", "measurement_plan")
    op.drop_table("measurement_target")
