"""Three more avatars: a red شماغ in two skin tones and a white غترة.

The account and the care circle both keep the chosen avatar under a check
that lists every code, so both checks get the new ones.

Revision ID: 0062
Revises: 0061
"""
from alembic import op

revision = "0062"
down_revision = "0061"
branch_labels = None
depends_on = None

_OLD = (
    "w1_1", "w1_3", "w6_1", "w6_3", "w7_1", "w7_3",
    "m1_1", "m1_3", "m2_1", "m2_3", "m6_1", "m6_3",
)
_NEW = ("sh_1", "sh_3", "gh_3")


def _checks(codes) -> None:
    choices = ", ".join(f"'{code}'" for code in codes)
    for table in ("account", "care_circle"):
        name = op.f(f"ck_{table}_avatar_code")
        op.drop_constraint(name, table, type_="check")
        op.create_check_constraint(
            name, table, f"avatar_code IS NULL OR avatar_code IN ({choices})"
        )


def upgrade() -> None:
    _checks(_OLD + _NEW)


def downgrade() -> None:
    # Whoever chose a new avatar goes back to their initial.
    new = ", ".join(f"'{code}'" for code in _NEW)
    for table in ("account", "care_circle"):
        op.execute(
            f"UPDATE {table} SET avatar_code = NULL "
            f"WHERE avatar_code IN ({new})"
        )
    _checks(_OLD)
