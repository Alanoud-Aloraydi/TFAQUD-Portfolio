"""An emergency contact's «أخرى» keeps the relation the user typed.

Contacts already saved as «أخرى» get the word «أخرى» itself, so they read
as they did; a new or changed one carries the user's words.

Revision ID: 0063
Revises: 0062
"""
import sqlalchemy as sa
from alembic import op

revision = "0063"
down_revision = "0062"
branch_labels = None
depends_on = None

_RULE = (
    "(relation = 'other' AND relation_other IS NOT NULL "
    "AND length(btrim(relation_other)) BETWEEN 1 AND 100) OR "
    "(relation <> 'other' AND relation_other IS NULL)"
)


def upgrade() -> None:
    op.add_column(
        "emergency_contact", sa.Column("relation_other", sa.Text())
    )
    op.execute(
        "UPDATE emergency_contact SET relation_other = 'أخرى' "
        "WHERE relation = 'other'"
    )
    op.create_check_constraint(
        op.f("ck_emergency_contact_relation_other"),
        "emergency_contact",
        _RULE,
    )


def downgrade() -> None:
    op.drop_constraint(
        op.f("ck_emergency_contact_relation_other"),
        "emergency_contact",
        type_="check",
    )
    op.drop_column("emergency_contact", "relation_other")
