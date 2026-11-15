"""The `care_circle_invitation` table."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db
from app.models.circle_request.formats import PHONE_FORMAT


class CareCircleInvitation(db.Model):
    """The ``care_circle_invitation`` table (API: /invitations): one
    pending invitation per circle and phone number."""

    __tablename__ = "care_circle_invitation"
    __table_args__ = (
        CheckConstraint(
            f"invitee_phone_number {PHONE_FORMAT}", name="phone_format"
        ),
        CheckConstraint(
            "status IN ('pending', 'accepted', 'declined', 'cancelled')",
            name="status",
        ),
        Index(
            "uq_care_circle_invitation_circle_invitee_phone_number_pending",
            "care_circle_id",
            "invitee_phone_number",
            unique=True,
            postgresql_where=text("status = 'pending'"),
        ),
        Index(
            "ix_care_circle_invitation_invitee_phone_number",
            "invitee_phone_number",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"),
        index=True,
    )
    # Null after the inviting account was deleted.
    invited_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )
    invitee_phone_number: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(Text, server_default="pending")
    # Null until answered, or after that account was deleted.
    responded_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
    last_sent_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )
    responded_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
    )
