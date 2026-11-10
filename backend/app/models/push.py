"""The phones that receive push notifications for a signed-in account."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class PushDevice(db.Model):
    """One phone's Apple push token, tied to the sign-in that sent it.

    The token belongs to the sign-in (session), not only to the account: a
    signed-out phone gets nothing, and deleting the account or the session
    deletes the row.
    """

    __tablename__ = "push_device"
    __table_args__ = (
        CheckConstraint("token ~ '^[0-9a-f]{64,200}$'", name="token_format"),
        CheckConstraint("updated_at >= created_at", name="update_order"),
    )

    token: Mapped[str] = mapped_column(Text, primary_key=True)
    account_id: Mapped[UUID] = mapped_column(
        ForeignKey("account.id", ondelete="CASCADE"), index=True
    )
    session_id: Mapped[UUID] = mapped_column(
        ForeignKey("account_session.id", ondelete="CASCADE"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
