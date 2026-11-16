"""Several visits booked together share a series.

A clinic hands over a sheet of dates that follow no rule: the 5th of
December, the 9th of January, the 14th of March. The app lets them be
chosen at once, and each date is saved as its own appointment, with its
own attendance, its own companions and its own visit paper. They are tied
only by `series_id`, so a card can say «الزيارة 2 من 6».

Nothing is generated from a rule, and an edit to one visit never reaches
the others: the column carries no behaviour of its own.

Every appointment saved before this is a visit on its own, and keeps a
null series.

Revision ID: 0058
Revises: 0057
"""
import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0058"
down_revision = "0057"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "appointment",
        sa.Column("series_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_index(
        op.f("ix_appointment_series_id"), "appointment", ["series_id"]
    )


def downgrade() -> None:
    op.drop_index(op.f("ix_appointment_series_id"), table_name="appointment")
    op.drop_column("appointment", "series_id")
