"""Store an optional target snapshot with a standalone reading.

Revision ID: 0014
Revises: 0013
"""

from alembic import op
import sqlalchemy as sa

revision = "0014"
down_revision = "0013"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Add bounded target columns and a shape constraint."""
    for name in (
        "glucose_low", "glucose_high", "systolic_limit", "diastolic_limit"
    ):
        op.add_column("measurement_record", sa.Column(name, sa.SmallInteger()))
    op.create_check_constraint(
        op.f("ck_measurement_record_free_target_shape"),
        "measurement_record",
        "(glucose_low IS NULL AND glucose_high IS NULL AND "
        "systolic_limit IS NULL AND diastolic_limit IS NULL) OR "
        "(plan_version_id IS NULL AND outcome = 'read' AND "
        "((kind = 'glucose' AND glucose_low IS NOT NULL AND "
        "glucose_high IS NOT NULL AND glucose_low BETWEEN 1 AND 999 "
        "AND glucose_high BETWEEN 1 AND 999 AND "
        "glucose_low < glucose_high AND systolic_limit IS NULL AND "
        "diastolic_limit IS NULL) OR "
        "(kind = 'bp' AND systolic_limit IS NOT NULL AND "
        "diastolic_limit IS NOT NULL AND "
        "systolic_limit BETWEEN 1 AND 999 AND "
        "diastolic_limit BETWEEN 1 AND 999 AND "
        "systolic_limit > diastolic_limit AND glucose_low IS NULL "
        "AND glucose_high IS NULL)))",
    )


def downgrade() -> None:
    """Remove standalone reading targets."""
    op.drop_constraint(
        op.f("ck_measurement_record_free_target_shape"),
        "measurement_record", type_="check",
    )
    for name in (
        "diastolic_limit", "systolic_limit", "glucose_high", "glucose_low"
    ):
        op.drop_column("measurement_record", name)
