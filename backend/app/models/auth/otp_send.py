"""The `otp_send` table."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


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
