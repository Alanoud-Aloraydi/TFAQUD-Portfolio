"""Invitations to manage existing circles, not requests to create care."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Text
from sqlalchemy import text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class CareCircleManagerInvitation(db.Model):
    """Keep one pending invitation for a circle and target phone."""

    __tablename__ = "care_circle_manager_invitation"
    __table_args__ = (
        CheckConstraint(
            "invitee_phone_number ~ '^\\+[1-9][0-9]{1,14}$'",
            name="phone_format",
        ),
        CheckConstraint(
            "status IN ('pending', 'accepted', 'declined', 'canceled')",
            name="status",
        ),
        Index(
            "uq_manager_invitation_pending",
            "care_circle_id",
            "invitee_phone_number",
            unique=True,
            postgresql_where=text("status = 'pending'"),
        ),
        Index("ix_manager_invitation_target", "invitee_phone_number"),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"),
        index=True,
    )
    invited_by_account_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("account.id", ondelete="SET NULL"),
        index=True,
    )
    invitee_phone_number: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(Text, server_default="pending")
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
