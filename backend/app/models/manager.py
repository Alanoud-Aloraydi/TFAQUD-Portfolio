"""Current management memberships, without global manager roles."""
from uuid import UUID

from sqlalchemy import Boolean, ForeignKey, UniqueConstraint, text
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
    # A membership stays in the circle when its owner pauses editing. This
    # keeps the circle visible and readable without granting write routes.
    can_edit: Mapped[bool] = mapped_column(
        Boolean, nullable=False, default=True, server_default=text("true")
    )
