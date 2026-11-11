"""Persistent sessions and provider-managed phone verification metadata."""
from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class AccountSession(db.Model):
    """One independently revocable sign-in; only refresh hashes are stored.

    It has no end date: it lasts until `revoked_at` is set (sign-out, the
    account deleted, or the app deleted from the phone).
    """

    __tablename__ = "account_session"
    __table_args__ = (
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
    # Null while the sign-in is live.
    revoked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )


class OtpRequest(db.Model):
    """The ``otp_request`` table: one request for a sign-in code to a phone.

    The application counts wrong codes; the provider owns the code itself.
    Kept 30 days (`app.push.scheduled.purge_old_rows`).
    """

    __tablename__ = "otp_request"
    __table_args__ = (
        CheckConstraint(
            "phone_number ~ '^\\+[1-9][0-9]{1,14}$'", name="phone_format"
        ),
        CheckConstraint("wrong_try_count >= 0", name="wrong_try_count"),
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
            "uq_otp_request_phone_number_pending",
            "phone_number",
            unique=True,
            postgresql_where=text("status = 'pending'"),
        ),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True)
    phone_number: Mapped[str] = mapped_column(Text, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    # Null until the first code is sent.
    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    wrong_try_count: Mapped[int] = mapped_column(server_default=text("0"))
    status: Mapped[str] = mapped_column(Text, server_default="pending")
    verified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )


class OtpSend(db.Model):
    """The ``otp_send`` table: one SMS reserved, sent or failed, so a quota
    holds even when the provider's answer is uncertain."""

    __tablename__ = "otp_send"
    __table_args__ = (
        CheckConstraint(
            "status IN ('reserved', 'sent', 'failed')", name="status"
        ),
        CheckConstraint(
            "(status = 'sent') = (sent_at IS NOT NULL)", name="delivery_state"
        ),
        CheckConstraint("sent_at >= created_at", name="delivery_order"),
        Index(
            "ix_otp_send_otp_request_id_created_at",
            "otp_request_id", "created_at",
        ),
        Index("ix_otp_send_device_id_created_at", "device_id", "created_at"),
        Index("ix_otp_send_client_ip_created_at", "client_ip", "created_at"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True)
    otp_request_id: Mapped[UUID] = mapped_column(
        ForeignKey("otp_request.id", ondelete="CASCADE")
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(Text, server_default="reserved")
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    # Who asked: the app's install id (X-Device-Id) and the network address,
    # for the caps of one device and one IP (see app.auth.otp_store); null
    # when the app or the network did not tell.
    device_id: Mapped[str | None] = mapped_column(Text)
    client_ip: Mapped[str | None] = mapped_column(Text)
