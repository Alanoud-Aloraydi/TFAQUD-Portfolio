"""Keep the birth date and city that onboarding asks for on the account."""

from alembic import op
import sqlalchemy as sa

revision = "0009"
down_revision = "0008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Both are optional: accounts made before this keep working."""
    op.add_column("account", sa.Column("birth_date", sa.Date()))
    op.add_column("account", sa.Column("city", sa.Text()))
    op.create_check_constraint(
        op.f("ck_account_birth_date"),
        "account",
        "birth_date IS NULL OR birth_date >= DATE '1900-01-01'",
    )
    op.create_check_constraint(
        op.f("ck_account_city"),
        "account",
        "city IS NULL OR length(btrim(city)) BETWEEN 1 AND 60",
    )


def downgrade() -> None:
    op.drop_constraint(op.f("ck_account_city"), "account", type_="check")
    op.drop_constraint(
        op.f("ck_account_birth_date"), "account", type_="check"
    )
    op.drop_column("account", "city")
    op.drop_column("account", "birth_date")
