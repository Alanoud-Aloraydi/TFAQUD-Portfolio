"""The `account_session` table."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Text, false
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class AccountSession(db.Model):
    """One independently revocable sign-in; only refresh hashes are stored.

    It has no end date: it lasts until `revoked_at` is set (sign-out, the
    account deleted, or the app deleted from the phone).
    """

    __tablename__ = "account_session"
    __table_args__ = (
        CheckConstraint("revoked_at >= created_at", name="revocation_order"),
        CheckConstraint(
            "refresh_token_hash ~ '^[0-9a-f]{64}$'", name="refresh_hash"
        ),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True)
    account_id: Mapped[UUID] = mapped_column(
        ForeignKey("account.id", ondelete="CASCADE"), index=True
    )
    refresh_token_hash: Mapped[str] = mapped_column(Text, unique=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    # Null while the sign-in is live.
    revoked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )
    # The OneSignal subscription of the phone this sign-in is on, which its
    # app sends after signing in (PUT /accounts/me/push-subscription). When
    # OneSignal reports that phone's app deleted, the sign-in ends
    # (app/push/notify.py). One phone belongs to one sign-in at a time.
    push_subscription_id: Mapped[UUID | None] = mapped_column(unique=True)
    # Whether the app on that phone leaves the reminders at the tasks'
    # times to the server (app/push/scheduled/reminders), as it asks with
    # its subscription; false for an app from before, which sets its own.
    server_reminders: Mapped[bool] = mapped_column(
        default=False, server_default=false()
    )
