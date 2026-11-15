"""The `otp_request` table."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, Index, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


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
