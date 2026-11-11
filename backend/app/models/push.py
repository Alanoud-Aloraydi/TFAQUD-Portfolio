"""The phones that receive push notifications for a signed-in account."""
from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class PushDevice(db.Model):
    """One phone's Apple push token, tied to the sign-in that sent it.

    The sign-in names the account (`account_session.account_id`), so a
    signed-out phone gets nothing, and deleting the account or the sign-in
    deletes the row. The token is unique; a phone that signs in again moves
    its token to the new sign-in.
    """

    __tablename__ = "push_device"
    __table_args__ = (
        CheckConstraint("token ~ '^[0-9a-f]{64,200}$'", name="token_format"),
        CheckConstraint("updated_at >= created_at", name="update_order"),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    token: Mapped[str] = mapped_column(Text, unique=True)
    session_id: Mapped[UUID] = mapped_column(
        ForeignKey("account_session.id", ondelete="CASCADE"), index=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
