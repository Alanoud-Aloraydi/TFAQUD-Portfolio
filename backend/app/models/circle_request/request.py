"""The `care_circle_request` table."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, ForeignKey, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.models.circle_request.request_rules import REQUEST_TABLE_ARGS


class CareCircleRequest(db.Model):
    """The ``care_circle_request`` table (API: /circle-requests)."""

    __tablename__ = "care_circle_request"
    __table_args__ = REQUEST_TABLE_ARGS

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    requested_by_account_id: Mapped[UUID] = mapped_column(
        ForeignKey("account.id", ondelete="CASCADE"),
        index=True,
    )
    patient_phone_number: Mapped[str] = mapped_column(Text)
    proposed_app_mode: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(Text, server_default="pending")
    # The circle the request made; null until it is completed.
    care_circle_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"),
        unique=True,
    )
    # Who answered; null until answered, or after that account was deleted.
    responded_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
    responded_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
    )
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
    )
