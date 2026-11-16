"""«بخار» in millilitres passes the plan check too.

0056 added the form to the version's own list, but the plan check
(fn_assert_medication_plan, run when a plan is saved) keeps its own list
of each form's dose units. It still had none for «بخار», so every such
medicine was refused, and the app showed it as data changed elsewhere.

The function is read from the database and only that list changes, so
whatever earlier migrations built around it stays as it is.

Revision ID: 0057
Revises: 0056
"""
from alembic import op
from sqlalchemy import text

revision = "0057"
down_revision = "0056"
branch_labels = None
depends_on = None

_INHALER = "('inhaler', 'puff'),"
_WITH_NEBULIZER = "('inhaler', 'puff'), ('nebulizer', 'mL'),"


def _rewrite(old: str, new: str) -> None:
    source = op.get_bind().execute(
        text(
            "SELECT pg_get_functiondef("
            "'fn_assert_medication_plan(uuid)'::regprocedure)"
        )
    ).scalar_one()
    if source.count(old) != 1:
        raise RuntimeError("fn_assert_medication_plan is not as expected")
    op.execute(source.replace(old, new))


def upgrade() -> None:
    _rewrite(_INHALER, _WITH_NEBULIZER)


def downgrade() -> None:
    # 0056's downgrade then turns any «بخار» plan into a liquid, which
    # is allowed in millilitres.
    _rewrite(_WITH_NEBULIZER, _INHALER)
