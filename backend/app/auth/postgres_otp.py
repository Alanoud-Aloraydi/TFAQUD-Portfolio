"""Atomic PostgreSQL quota claims for provider-managed OTP verification."""

import hashlib
from uuid import UUID, uuid4

from sqlalchemy import func, select, text, update

from app.auth.otp_store import (
    AttemptsExhausted,
    OtpRequest,
    OtpStore,
    SendClaim,
    SendRules,
    judge_send,
    next_send_at,
)
from app.database import transaction
from app.models import OtpRequest as OtpRequestRow
from app.models import OtpSend


def _key(value):
    """Treat malformed public identifiers as missing records."""
    try:
        return UUID(value)
    except (ValueError, TypeError, AttributeError):
        return None


def _lock_phone(session, phone):
    """Serialize phone quota claims, including phones without accounts."""
    digest = hashlib.sha256(phone.encode()).digest()[:8]
    session.execute(
        text("SELECT pg_advisory_xact_lock(:key)"),
        {"key": int.from_bytes(digest, "big", signed=True)},
    )


class PostgresOtpStore(OtpStore):
    """Own short transactions; no provider call holds a database lock."""

    def get_request(self, request_id):
        """The request with this id, or None (also for an id that is not a
        UUID).
        """
        # An id that is not a UUID is no request.
        key = _key(request_id)
        if key is None:
            return None
        with transaction() as session:
            row = session.get(OtpRequestRow, key)
            if row is None:
                return None
            return OtpRequest(
                id=row.id.hex,
                phone=row.phone_number,
                created_at=row.created_at,
                wrong_tries=row.wrong_try_count,
                verified_at=row.verified_at,
                status=row.status,
                expires_at=row.expires_at,
            )

    def claim_send(
        self,
        request_id,
        phone,
        now,
        window_start,
        max_sends,
        *,
        max_tries=None,
        rules=None
    ):
        """See OtpStore.claim_send: with the phone number locked (an advisory
        lock, so it works for a number without an account), judge the limits,
        then reserve the send, and create the request when there is none.
        """
        judged = rules or SendRules()
        with transaction() as session:
            # One claim per number at a time; a resend must name this number's
            # open request with tries left.
            _lock_phone(session, phone)
            row = (
                self._open_request(session, request_id, phone, now, max_tries)
                if request_id is not None
                else None
            )
            # The number's codes count only after its last accepted code.
            since = window_start
            known = False
            if rules is not None:
                verified = session.scalar(
                    select(func.max(OtpRequestRow.verified_at)).where(
                        OtpRequestRow.phone_number == phone
                    )
                )
                if verified is not None:
                    since = max(since, verified)
                known = self._is_known_phone(session, phone, rules.device_id)
            # The number's codes that count: in the window, not failed.
            counted = select(OtpSend.created_at).join(
                OtpRequestRow,
                OtpRequestRow.id == OtpSend.otp_request_id,
            ).where(
                OtpRequestRow.phone_number == phone,
                OtpSend.status != "failed",
                OtpSend.created_at > since,
            )
            if known:
                # The owner's phone: strangers' codes do not block it.
                counted = counted.where(
                    OtpSend.device_id == rules.device_id
                )
            phone_times = list(session.scalars(counted))
            # The asking device's and IP's codes in the last hour, for any
            # number (no IP cap for a known phone).
            device_times = self._asker_times(
                session,
                OtpSend.device_id,
                judged.device_id if rules is not None else None,
                now - judged.requester_window,
            )
            ip_times = self._asker_times(
                session,
                OtpSend.client_ip,
                judged.client_ip if rules is not None and not known else None,
                now - judged.requester_window,
            )
            # Judge every limit at once.
            window = now - window_start
            retry_at, reason = judge_send(
                now, phone_times, window, max_sends, judged,
                device_times, ip_times,
            )
            if retry_at is not None:
                return SendClaim(
                    granted=False,
                    retry_at=retry_at,
                    reason=reason,
                )
            # Make the request when there is none, reserve the send, and say
            # when the next code may come.
            if row is None:
                row = self._open_request(session, None, phone, now, max_tries)
            send = OtpSend(
                id=uuid4(),
                otp_request_id=row.id,
                created_at=now,
                device_id=judged.device_id,
                client_ip=judged.client_ip,
            )
            session.add(send)
            session.flush()
            return SendClaim(
                granted=True,
                request_id=row.id.hex,
                send_id=send.id.hex,
                next_send_at=next_send_at(
                    now, phone_times, window, max_sends, judged
                ),
            )

    @staticmethod
    def _is_known_phone(session, phone, device_id):
        """Whether this device already signed in with this number: it asked
        for a code that was accepted."""
        if not device_id:
            return False
        return session.scalar(
            select(OtpSend.id)
            .join(
                OtpRequestRow, OtpRequestRow.id == OtpSend.otp_request_id
            )
            .where(
                OtpRequestRow.phone_number == phone,
                OtpRequestRow.verified_at.is_not(None),
                OtpSend.device_id == device_id,
            )
            .limit(1)
        ) is not None

    @staticmethod
    def _asker_times(session, column, value, start):
        """The times of the counted sends one device or one IP asked for."""
        if not value:
            return []
        return list(
            session.scalars(
                select(OtpSend.created_at).where(
                    column == value,
                    OtpSend.status != "failed",
                    OtpSend.created_at > start,
                )
            )
        )

    @staticmethod
    def _open_request(session, request_id, phone, now, max_tries):
        """Recheck a resend under lock, or supersede older open requests."""
        # A resend: this number's open request, locked, with tries left.
        if request_id is not None:
            key = _key(request_id)
            row = (
                session.get(OtpRequestRow, key, with_for_update=True)
                if key
                else None
            )
            if (
                row is None
                or row.phone_number != phone
                or row.status != "pending"
            ):
                raise KeyError(request_id)
            if max_tries is not None and row.wrong_try_count >= max_tries:
                raise AttemptsExhausted()
            return row
        # A new request replaces the number's open one.
        session.execute(
            update(OtpRequestRow)
            .where(
                OtpRequestRow.phone_number == phone,
                OtpRequestRow.status == "pending",
            )
            .values(status="superseded")
        )
        row = OtpRequestRow(id=uuid4(), phone_number=phone, created_at=now)
        session.add(row)
        session.flush()
        return row

    def mark_sent(self, send_id, at, expires_at):
        """Mark the reserved send as sent, and keep the request open until the
        newest code's end.
        """
        # Only a reserved send becomes sent; the open request then lasts until
        # this code's end, never shorter.
        with transaction() as session:
            send = session.get(
                OtpSend, _key(send_id), with_for_update=True
            )
            if send is None or send.status != "reserved":
                return
            send.status, send.sent_at = "sent", at
            session.execute(
                update(OtpRequestRow)
                .where(
                    OtpRequestRow.id == send.otp_request_id,
                    OtpRequestRow.status == "pending",
                    (OtpRequestRow.expires_at.is_(None))
                    | (OtpRequestRow.expires_at < expires_at),
                )
                .values(expires_at=expires_at)
            )

    def release_send(self, send_id):
        """Give a reserved place back: the provider refused, so no code left.
        """
        key = _key(send_id)
        if key is None:
            return
        with transaction() as session:
            session.execute(
                update(OtpSend)
                .where(
                    OtpSend.id == key,
                    OtpSend.status == "reserved",
                )
                .values(status="failed")
            )

    def latest_send_at(self, request_id):
        """When the request's last code was sent, or None."""
        key = _key(request_id)
        if key is None:
            return None
        with transaction() as session:
            return session.scalar(
                select(func.max(OtpSend.sent_at)).where(
                    OtpSend.otp_request_id == key,
                    OtpSend.status == "sent",
                )
            )

    def claim_try(self, request_id, max_tries):
        """Count one try on an open request with tries left, in one statement;
        False otherwise.
        """
        return self._update_request(
            request_id,
            OtpRequestRow.wrong_try_count < max_tries,
            wrong_try_count=OtpRequestRow.wrong_try_count + 1,
        )

    def release_try(self, request_id):
        """Take back a try the provider could not decide, never below zero."""
        self._update_request(
            request_id,
            OtpRequestRow.wrong_try_count > 0,
            wrong_try_count=OtpRequestRow.wrong_try_count - 1,
        )

    def mark_verified(self, request_id, at):
        """Close an open request as accepted; False when it was already closed
        or unknown.
        """
        return self._update_request(
            request_id,
            OtpRequestRow.verified_at.is_(None),
            status="verified",
            verified_at=at,
        )

    @staticmethod
    def _update_request(request_id, condition, **values):
        """Check and change a pending request in one statement."""
        key = _key(request_id)
        if key is None:
            return False
        # One statement checks and changes, so two calls at once cannot both
        # pass; True when a row changed.
        with transaction() as session:
            return (
                session.execute(
                    update(OtpRequestRow)
                    .where(
                        OtpRequestRow.id == key,
                        OtpRequestRow.status == "pending",
                        condition,
                    )
                    .values(**values)
                ).rowcount
                > 0
            )
