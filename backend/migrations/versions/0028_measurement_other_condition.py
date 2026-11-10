"""«أخرى» in the reader's own words.

A reading with the condition «أخرى» can say what it was: «بعد القهوة».
Up to 60 characters, and only with «أخرى».

Revision ID: 0028
Revises: 0027
"""

from alembic import op
import sqlalchemy as sa

revision = "0028"
down_revision = "0027"
branch_labels = None
depends_on = None

_CHECK = "ck_measurement_record_other_condition"


def upgrade() -> None:
    op.add_column(
        "measurement_record", sa.Column("other_condition", sa.Text())
    )
    op.create_check_constraint(
        op.f(_CHECK),
        "measurement_record",
        "other_condition IS NULL OR (char_length(other_condition) "
        "BETWEEN 1 AND 60 AND 'other' = ANY(conditions))",
    )


def downgrade() -> None:
    op.drop_constraint(op.f(_CHECK), "measurement_record", type_="check")
    op.drop_column("measurement_record", "other_condition")
