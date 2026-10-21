"""Persistent sessions and provider-managed phone verification metadata."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class AccountSession(db.Model):
    """One independently revocable sign-in; only refresh hashes are stored."""

    __tablename__ = "account_session"
    __table_args__ = (
        CheckConstraint(
            "refresh_expires_at > created_at", name="expiry_order"
        ),
        CheckConstraint("revoked_at >= created_at", name="revocation_order"),
        CheckConstraint(
            "refresh_token_hash ~ '^[0-9a-f]{64}$'", name="refresh_hash"
        ),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True)
    account_id: Mapped[UUID] = mapped_column(
        ForeignKey("account.id", ondelete="CASCADE"), index=True
    )
    refresh_token_hash: Mapped[str] = mapped_column(Text, unique=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    refresh_expires_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True)
    )
    revoked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )


class OtpChallenge(db.Model):
    """The application tracks attempts; the provider owns the OTP secret."""

    __tablename__ = "otp_challenge"
    __table_args__ = (
        CheckConstraint(
            "phone_number ~ '^\\+[1-9][0-9]{1,14}$'", name="phone_format"
        ),
        CheckConstraint("attempt_count >= 0", name="attempt_count"),
        CheckConstraint(
            "status IN ('pending', 'verified', 'superseded')", name="status"
        ),
        CheckConstraint(
            "(status = 'verified') = (verified_at IS NOT NULL)",
            name="verification_state",
        ),
        CheckConstraint(
            "verified_at >= created_at", name="verification_order"
        ),
        CheckConstraint("expires_at > created_at", name="expiry_order"),
        Index(
            "uq_otp_challenge_pending_phone",
            "phone_number",
            unique=True,
            postgresql_where=text("status = 'pending'"),
        ),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True)
    phone_number: Mapped[str] = mapped_column(Text, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    attempt_count: Mapped[int] = mapped_column(server_default=text("0"))
    status: Mapped[str] = mapped_column(Text, server_default="pending")
    verified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )


class OtpSendAttempt(db.Model):
    """Reserve quota before delivery, retaining uncertain delivery attempts."""

    __tablename__ = "otp_send_attempt"
    __table_args__ = (
        CheckConstraint(
            "status IN ('reserved', 'sent', 'failed')", name="status"
        ),
        CheckConstraint(
            "(status = 'sent') = (sent_at IS NOT NULL)", name="delivery_state"
        ),
        CheckConstraint("sent_at >= created_at", name="delivery_order"),
        Index(
            "ix_otp_send_attempt_challenge_time", "challenge_id", "created_at"
        ),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True)
    challenge_id: Mapped[UUID] = mapped_column(
        ForeignKey("otp_challenge.id", ondelete="CASCADE")
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(Text, server_default="reserved")
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
