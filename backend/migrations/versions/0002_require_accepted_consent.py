"""Require an identified, timestamped consent while activation is pending."""

from alembic import op

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade():
    """Keep accepted requests tied to a live patient until resolved."""
    op.create_check_constraint(
        op.f("ck_care_circle_creation_request_consent"),
        "care_circle_creation_request",
        "status <> 'accepted' OR (responded_by_account_id IS NOT NULL "
        "AND responded_at IS NOT NULL)",
    )


def downgrade():
    """Remove the pending-consent constraint."""
    op.drop_constraint(
        op.f("ck_care_circle_creation_request_consent"),
        "care_circle_creation_request",
        type_="check",
    )
