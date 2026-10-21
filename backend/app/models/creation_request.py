"""Consent requests which precede circle activation."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Text
from sqlalchemy import text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class CareCircleCreationRequest(db.Model):
    """Acceptance is consent; completion is the atomic creation of care."""

    __tablename__ = "care_circle_creation_request"
    __table_args__ = (
        CheckConstraint(
            "patient_phone_number ~ '^\\+[1-9][0-9]{1,14}$'",
            name="phone_format",
        ),
        CheckConstraint(
            "length(btrim(proposed_circle_label)) > 0",
            name="label",
        ),
        CheckConstraint(
            "proposed_app_mode IN ('detailed', 'simplified')",
            name="mode",
        ),
        CheckConstraint(
            "status IN ('pending', 'accepted', 'completed', 'declined', "
            "'canceled', 'superseded')",
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
            "uq_creation_request_active",
            "requested_by_account_id",
            "patient_phone_number",
            unique=True,
            postgresql_where=text("status IN ('pending', 'accepted')"),
        ),
        Index(
            "uq_creation_request_accepted",
            "responded_by_account_id",
            unique=True,
            postgresql_where=text("status = 'accepted'"),
        ),
        Index("ix_creation_request_target", "patient_phone_number"),
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
    proposed_circle_label: Mapped[str] = mapped_column(Text)
    proposed_app_mode: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(Text, server_default="pending")
    care_circle_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"),
        unique=True,
    )
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
