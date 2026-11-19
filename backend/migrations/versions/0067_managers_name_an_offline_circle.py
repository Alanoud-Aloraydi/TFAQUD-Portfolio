"""A circle whose patient has no account can have a name: its managers
choose it, as they choose the patient's picture, and everyone sees it.
Until then everyone still sees «دائرة» and the first name.

Revision ID: 0067
Revises: 0066
"""
from alembic import op

revision = "0067"
down_revision = "0066"
branch_labels = None
depends_on = None

_WITH_ACCOUNT = (
    "(account_id IS NOT NULL AND name IS NOT NULL AND first_name IS NULL "
    "AND last_name IS NULL AND avatar_code IS NULL AND birth_date IS NULL "
    "AND city IS NULL)"
)
_WITHOUT_ACCOUNT = (
    "(account_id IS NULL{name} AND first_name IS NOT NULL "
    "AND last_name IS NOT NULL AND birth_date IS NOT NULL "
    "AND city IS NOT NULL)"
)


def _source(*, names_allowed: bool) -> None:
    op.drop_constraint(
        op.f("ck_care_circle_account_source"), "care_circle", type_="check"
    )
    without = _WITHOUT_ACCOUNT.format(
        name="" if names_allowed else " AND name IS NULL"
    )
    op.create_check_constraint(
        op.f("ck_care_circle_account_source"),
        "care_circle",
        f"{_WITH_ACCOUNT} OR {without}",
    )


def upgrade() -> None:
    _source(names_allowed=True)


def downgrade() -> None:
    # The managers' names go back to the automatic one.
    op.execute("UPDATE care_circle SET name = NULL WHERE account_id IS NULL")
    _source(names_allowed=False)
