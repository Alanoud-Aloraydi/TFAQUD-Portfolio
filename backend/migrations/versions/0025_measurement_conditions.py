"""«ظروف القياس»: a reading time or a reading has one or more conditions.

A glucose reading can be after a meal and after exercise at once, so
`conditions` is a list on each plan reading time and each record. The new
codes «بعد جهد» (exertion) and «بعد توتر» (stress) join the old meal states.

Every existing row gets its old `glucose_context` and `condition` as its
conditions. Those two columns stay, holding one of each, for an older app.
A downgrade drops the lists and keeps those two.

Revision ID: 0025
Revises: 0024
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "0025"
down_revision = "0024"
branch_labels = None
depends_on = None

_CHECK = (
    "conditions <@ ARRAY['fasting', 'before_meal', 'after_meal', 'bedtime', "
    "'exertion', 'stress', 'illness', 'other']::text[]"
)
_TABLES = ("measurement_plan_time", "measurement_record")


def upgrade() -> None:
    for table in _TABLES:
        op.add_column(
            table,
            sa.Column(
                "conditions",
                postgresql.ARRAY(sa.Text()),
                server_default=sa.text("'{}'"),
                nullable=False,
            ),
        )
        op.create_check_constraint(
            op.f(f"ck_{table}_conditions"), table, _CHECK
        )
    op.execute(
        "UPDATE measurement_plan_time SET conditions = ARRAY[glucose_context] "
        "WHERE glucose_context IS NOT NULL"
    )
    # A reading's context first, then its condition, once each.
    op.execute(
        "UPDATE measurement_record SET conditions = CASE "
        "WHEN condition IS NULL OR condition = glucose_context "
        "THEN ARRAY[glucose_context] "
        "WHEN glucose_context IS NULL THEN ARRAY[condition] "
        "ELSE ARRAY[glucose_context, condition] END "
        "WHERE glucose_context IS NOT NULL OR condition IS NOT NULL"
    )


def downgrade() -> None:
    for table in reversed(_TABLES):
        op.drop_constraint(
            op.f(f"ck_{table}_conditions"), table, type_="check"
        )
        op.drop_column(table, "conditions")
