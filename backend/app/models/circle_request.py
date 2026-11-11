"""Circle requests and circle invitations: the two ways someone joins care.

A circle request asks a phone number to become the patient of a new circle
(acceptance is consent; completion creates the circle). A circle
invitation asks a phone number to manage an existing circle.
"""
from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Text
from sqlalchemy import text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db

PHONE_FORMAT = "~ '^\\+[1-9][0-9]{1,14}$'"


class CareCircleRequest(db.Model):
    """The ``care_circle_request`` table (API: /circle-requests)."""

    __tablename__ = "care_circle_request"
    __table_args__ = (
        CheckConstraint(
            f"patient_phone_number {PHONE_FORMAT}", name="phone_format"
        ),
        CheckConstraint(
            "proposed_app_mode IN ('detailed', 'simplified')",
            name="proposed_app_mode",
        ),
        CheckConstraint(
            "status IN ('pending', 'accepted', 'completed', 'declined', "
            "'cancelled', 'superseded')",
            name="status",
        ),
        CheckConstraint(
            "(status = 'completed' AND care_circle_id IS NOT NULL "
            "AND completed_at IS NOT NULL) OR "
            "(status <> 'completed' AND care_circle_id IS NULL "
            "AND completed_at IS NULL)",
            name="completion",
        ),
        CheckConstraint(
            "status <> 'accepted' OR (responded_by_account_id IS NOT NULL "
            "AND responded_at IS NOT NULL)",
            name="consent",
        ),
        Index(
            "uq_care_circle_request_requested_by_patient_phone_number_open",
            "requested_by_account_id",
            "patient_phone_number",
            unique=True,
            postgresql_where=text("status IN ('pending', 'accepted')"),
        ),
        Index(
            "uq_care_circle_request_responded_by_account_id_accepted",
            "responded_by_account_id",
            unique=True,
            postgresql_where=text("status = 'accepted'"),
        ),
        Index(
            "ix_care_circle_request_patient_phone_number",
            "patient_phone_number",
        ),
    )

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
