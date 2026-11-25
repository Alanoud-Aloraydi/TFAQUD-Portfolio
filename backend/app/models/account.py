"""An account and how it signs in: the `account` table (one row per
phone-verified person), its sign-ins (`account_session`), and the requests
for a sign-in code with each SMS sent for them (`otp_request`,
`otp_send`)."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Index,
    Text,
    false,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.database import db


class Account(db.Model):
    """The ``account`` table: one row per phone-verified person.

    Created at the first sign-in with the phone number only; onboarding then
    fills the names, birth date and city through PUT
    /api/v1/accounts/me/profile. The names are all null or all set, with the
    lengths the API checks (``profile_names``). Caring for a circle is a
    separate membership row, not a column here.
    """

    __tablename__ = "account"
    __table_args__ = (
        CheckConstraint(
            "phone_number ~ '^\\+[1-9][0-9]{1,14}$'",
            name="phone_format",
        ),
        CheckConstraint(
            "app_mode IN ('detailed', 'simplified')",
            name="app_mode",
        ),
        CheckConstraint(
            "(first_name IS NULL AND last_name IS NULL "
            "AND display_name IS NULL) OR "
            "(first_name IS NOT NULL AND last_name IS NOT NULL "
            "AND display_name IS NOT NULL "
            "AND length(btrim(first_name)) BETWEEN 1 AND 50 "
            "AND length(btrim(last_name)) BETWEEN 1 AND 50 "
            "AND length(btrim(display_name)) BETWEEN 1 AND 30)",
            name="profile_names",
        ),
        CheckConstraint(
            "birth_date IS NULL OR birth_date >= DATE '1900-01-01'",
            name="birth_date",
        ),
        CheckConstraint(
            "city IS NULL OR length(btrim(city)) BETWEEN 1 AND 60",
            name="city",
        ),
        CheckConstraint(
            "avatar_code IS NULL OR avatar_code IN "
            "('w1_1', 'w1_3', 'w6_1', 'w6_3', 'w7_1', 'w7_3', "
            "'m1_1', 'm1_3', 'm2_1', 'm2_3', 'm6_1', 'm6_3', "
            "'sh_1', 'sh_3', 'gh_3')",
            name="avatar_code",
        ),
    )

    id: Mapped[UUID] = mapped_column(
        primary_key=True,
        server_default=text("gen_random_uuid()"),
    )
    phone_number: Mapped[str] = mapped_column(Text, unique=True)
    first_name: Mapped[str | None] = mapped_column(
        Text,
        comment="Null until onboarding saves the profile.",
    )
    last_name: Mapped[str | None] = mapped_column(Text)
    display_name: Mapped[str | None] = mapped_column(Text)
    avatar_code: Mapped[str | None] = mapped_column(Text)
    app_mode: Mapped[str | None] = mapped_column(
        Text,
        comment="Null until the account first joins care.",
    )
    # Asked once at onboarding, so a circle for the person's own care needs
    # only its name. A circle copies them into its patient when it is
    # created.
    birth_date: Mapped[date | None] = mapped_column(
        comment=(
            "Null for an account made before onboarding asked; required once "
            "the account is a patient."
        ),
    )
    city: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=text("now()"),
    )


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
    # times to the server (app/push/reminders.py), as it asks with
    # its subscription; false for an app from before, which sets its own.
    server_reminders: Mapped[bool] = mapped_column(
        default=False, server_default=false()
    )


class OtpRequest(db.Model):
    """The ``otp_request`` table: one request for a sign-in code to a phone.

    The application counts wrong codes; the provider owns the code itself.
    Kept 30 days (`app.push.scheduled.purge_old_rows`).
    """

    __tablename__ = "otp_request"
    __table_args__ = (
        CheckConstraint(
            "phone_number ~ '^\\+[1-9][0-9]{1,14}$'", name="phone_format"
        ),
        CheckConstraint("wrong_try_count >= 0", name="wrong_try_count"),
        CheckConstraint(
            "status IN ('pending', 'verified', 'superseded')", name="status"
        ),
        CheckConstraint(
            "(status = 'verified') = (verified_at IS NOT NULL)",
            name="verification_state",
        ),
        CheckConstraint(
            "verified_at >= created_at", name="verification_order"
        ),
        CheckConstraint("expires_at > created_at", name="expiry_order"),
        Index(
            "uq_otp_request_phone_number_pending",
            "phone_number",
            unique=True,
            postgresql_where=text("status = 'pending'"),
        ),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True)
    phone_number: Mapped[str] = mapped_column(Text, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    expires_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        comment="Null until the first code is sent.",
    )
    wrong_try_count: Mapped[int] = mapped_column(server_default=text("0"))
    status: Mapped[str] = mapped_column(Text, server_default="pending")
    verified_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True)
    )


class OtpSend(db.Model):
    """The ``otp_send`` table: one SMS reserved, sent or failed, so a quota
    holds even when the provider's answer is uncertain."""

    __tablename__ = "otp_send"
    __table_args__ = (
        CheckConstraint(
            "status IN ('reserved', 'sent', 'failed')", name="status"
        ),
        CheckConstraint(
            "(status = 'sent') = (sent_at IS NOT NULL)", name="delivery_state"
        ),
        CheckConstraint("sent_at >= created_at", name="delivery_order"),
        Index(
            "ix_otp_send_otp_request_id_created_at",
            "otp_request_id", "created_at",
        ),
        Index("ix_otp_send_device_id_created_at", "device_id", "created_at"),
        Index("ix_otp_send_client_ip_created_at", "client_ip", "created_at"),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True)
    otp_request_id: Mapped[UUID] = mapped_column(
        ForeignKey("otp_request.id", ondelete="CASCADE")
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    status: Mapped[str] = mapped_column(Text, server_default="reserved")
    sent_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    # Who asked: the app's install id (X-Device-Id) and the network address,
    # for the caps of one device and one IP (see app.auth.otp_store); null
    # when the app or the network did not tell.
    device_id: Mapped[str | None] = mapped_column(Text)
    client_ip: Mapped[str | None] = mapped_column(Text)
