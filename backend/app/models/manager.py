"""Current management memberships, without global manager roles."""
from uuid import UUID

from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, UniqueConstraint, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class CareCircleManager(db.Model):
    """An account can manage many circles, once in each circle."""

    __tablename__ = "care_circle_manager"
    __table_args__ = (
        UniqueConstraint(
            "care_circle_id", "account_id",
            name="uq_care_circle_manager_care_circle_id_account_id",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    care_circle_id: Mapped[UUID] = mapped_column(
        ForeignKey("care_circle.id", ondelete="CASCADE"),
    )
    # The server removes a membership before the account goes, so the
    # database refuses a deletion that skipped that step.
    account_id: Mapped[UUID] = mapped_column(
        ForeignKey("account.id", ondelete="RESTRICT"),
        index=True,
    )
    # The circle's leader lets each member edit the medicines, the
    # measurements and the appointments, or not (`app.circles.leader`). A
    # membership with all three off stays in the circle, readable, without
    # any write route.
    can_edit_medications: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default=text("true")
    )
    can_edit_measurements: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default=text("true")
    )
    can_edit_appointments: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default=text("true")
    )
    # When the account joined: the leadership falls to the member who joined
    # first when the leader leaves.
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )

    def may_edit(self, area: str) -> bool:
        """Whether this member may edit the `area` («medications»,
        «measurements» or «appointments»)."""
        return bool(getattr(self, f"can_edit_{area}"))

    @property
    def can_edit_any(self) -> bool:
        """Whether this member may edit at least one area."""
        return (
            self.can_edit_medications
            or self.can_edit_measurements
            or self.can_edit_appointments
        )
