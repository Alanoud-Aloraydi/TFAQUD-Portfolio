"""Persist sessions, verification requests, and SMS delivery reservations."""

from alembic import op
import sqlalchemy as sa

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def _sessions():
    """Keep refresh hashes and durable revocation per account sign-in."""
    op.create_table(
        "account_session",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "account_id",
            sa.Uuid(),
            sa.ForeignKey("account.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "refresh_token_hash", sa.Text(), nullable=False, unique=True
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "refresh_expires_at", sa.DateTime(timezone=True), nullable=False
        ),
        sa.Column("revoked_at", sa.DateTime(timezone=True)),
        sa.CheckConstraint(
            "refresh_expires_at > created_at", name="expiry_order"
        ),
        sa.CheckConstraint(
            "revoked_at >= created_at", name="revocation_order"
        ),
        sa.CheckConstraint(
            "refresh_token_hash ~ '^[0-9a-f]{64}$'", name="refresh_hash"
        ),
    )
    op.create_index(
        "ix_account_session_account_id", "account_session", ["account_id"]
    )


def _challenges():
    """Allow at most one pending challenge for each normalized phone."""
    op.create_table(
        "otp_challenge",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column("phone_number", sa.Text(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True)),
        sa.Column(
            "attempt_count", sa.Integer(), nullable=False, server_default="0"
        ),
        sa.Column(
            "status", sa.Text(), nullable=False, server_default="pending"
        ),
        sa.Column("verified_at", sa.DateTime(timezone=True)),
        sa.CheckConstraint(
            "phone_number ~ '^\\+[1-9][0-9]{1,14}$'", name="phone_format"
        ),
        sa.CheckConstraint("attempt_count >= 0", name="attempt_count"),
        sa.CheckConstraint(
            "status IN ('pending', 'verified', 'superseded')", name="status"
        ),
        sa.CheckConstraint(
            "(status = 'verified') = (verified_at IS NOT NULL)",
            name="verification_state",
        ),
        sa.CheckConstraint(
            "verified_at >= created_at", name="verification_order"
        ),
        sa.CheckConstraint("expires_at > created_at", name="expiry_order"),
    )
    op.create_index(
        "ix_otp_challenge_phone_number", "otp_challenge", ["phone_number"]
    )
    op.create_index(
        "uq_otp_challenge_pending_phone",
        "otp_challenge",
        ["phone_number"],
        unique=True,
        postgresql_where=sa.text("status = 'pending'"),
    )


def _sends():
    """Record delivery uncertainty without storing the OTP secret."""
    op.create_table(
        "otp_send_attempt",
        sa.Column("id", sa.Uuid(), primary_key=True),
        sa.Column(
            "challenge_id",
            sa.Uuid(),
            sa.ForeignKey("otp_challenge.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column(
            "status", sa.Text(), nullable=False, server_default="reserved"
        ),
        sa.Column("sent_at", sa.DateTime(timezone=True)),
        sa.CheckConstraint(
            "status IN ('reserved', 'sent', 'failed')", name="status"
        ),
        sa.CheckConstraint(
            "(status = 'sent') = (sent_at IS NOT NULL)", name="delivery_state"
        ),
        sa.CheckConstraint("sent_at >= created_at", name="delivery_order"),
    )
    op.create_index(
        "ix_otp_send_attempt_challenge_time",
        "otp_send_attempt",
        ["challenge_id", "created_at"],
    )


def upgrade():
    """Add authentication tables without altering existing care data."""
    _sessions()
    _challenges()
    _sends()


def downgrade():
    """Remove only the authentication persistence introduced here."""
    op.drop_table("otp_send_attempt")
    op.drop_table("otp_challenge")
    op.drop_table("account_session")
