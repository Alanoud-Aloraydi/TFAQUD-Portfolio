"""Atomic PostgreSQL quota claims for provider-managed OTP verification."""

import hashlib
from uuid import UUID, uuid4

from sqlalchemy import func, select, text, update

from app.auth.otp_store import (
    AttemptsExhausted,
    OtpRequest,
    OtpStore,
    SendClaim,
)
from app.database import transaction
from app.models import OtpChallenge, OtpSendAttempt


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
        key = _key(request_id)
        if key is None:
            return None
        with transaction() as session:
            row = session.get(OtpChallenge, key)
            if row is None:
                return None
            return OtpRequest(
                id=row.id.hex,
                phone=row.phone_number,
                created_at=row.created_at,
                wrong_tries=row.attempt_count,
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
        max_tries=None
    ):
        with transaction() as session:
            _lock_phone(session, phone)
            row = (
                self._challenge(session, request_id, phone, now, max_tries)
                if request_id is not None
                else None
            )
            count, oldest = session.execute(
                select(func.count(), func.min(OtpSendAttempt.created_at))
                .join(
                    OtpChallenge,
                    OtpChallenge.id == OtpSendAttempt.challenge_id,
                )
                .where(
                    OtpChallenge.phone_number == phone,
                    OtpSendAttempt.status != "failed",
                    OtpSendAttempt.created_at > window_start,
                )
            ).one()
            if count >= max_sends:
                return SendClaim(granted=False, oldest_send_at=oldest)
            if row is None:
                row = self._challenge(session, None, phone, now, max_tries)
            send = OtpSendAttempt(
                id=uuid4(), challenge_id=row.id, created_at=now
            )
            session.add(send)
            session.flush()
            return SendClaim(
                granted=True, request_id=row.id.hex, send_id=send.id.hex
            )

    @staticmethod
    def _challenge(session, request_id, phone, now, max_tries):
        """Recheck a resend under lock, or supersede older open requests."""
        if request_id is not None:
            key = _key(request_id)
            row = (
                session.get(OtpChallenge, key, with_for_update=True)
                if key
                else None
            )
            if (
                row is None
                or row.phone_number != phone
                or row.status != "pending"
            ):
                raise KeyError(request_id)
            if max_tries is not None and row.attempt_count >= max_tries:
                raise AttemptsExhausted()
            return row
        session.execute(
            update(OtpChallenge)
            .where(
                OtpChallenge.phone_number == phone,
                OtpChallenge.status == "pending",
            )
            .values(status="superseded")
        )
        row = OtpChallenge(id=uuid4(), phone_number=phone, created_at=now)
        session.add(row)
        session.flush()
        return row

    def mark_sent(self, send_id, at, expires_at):
        with transaction() as session:
            send = session.get(
                OtpSendAttempt, _key(send_id), with_for_update=True
            )
            if send is None or send.status != "reserved":
                return
            send.status, send.sent_at = "sent", at
            session.execute(
                update(OtpChallenge)
                .where(
                    OtpChallenge.id == send.challenge_id,
                    OtpChallenge.status == "pending",
                    (OtpChallenge.expires_at.is_(None))
                    | (OtpChallenge.expires_at < expires_at),
                )
                .values(expires_at=expires_at)
            )

    def release_send(self, send_id):
        key = _key(send_id)
        if key is None:
            return
        with transaction() as session:
            session.execute(
                update(OtpSendAttempt)
                .where(
                    OtpSendAttempt.id == key,
                    OtpSendAttempt.status == "reserved",
                )
                .values(status="failed")
            )

    def latest_send_at(self, request_id):
        key = _key(request_id)
        if key is None:
            return None
        with transaction() as session:
            return session.scalar(
                select(func.max(OtpSendAttempt.sent_at)).where(
                    OtpSendAttempt.challenge_id == key,
                    OtpSendAttempt.status == "sent",
                )
            )

    def claim_try(self, request_id, max_tries):
        return self._update_request(
            request_id,
            OtpChallenge.attempt_count < max_tries,
            attempt_count=OtpChallenge.attempt_count + 1,
        )

    def release_try(self, request_id):
        self._update_request(
            request_id,
            OtpChallenge.attempt_count > 0,
            attempt_count=OtpChallenge.attempt_count - 1,
        )

    def mark_verified(self, request_id, at):
        return self._update_request(
            request_id,
            OtpChallenge.verified_at.is_(None),
            status="verified",
            verified_at=at,
        )

    @staticmethod
    def _update_request(request_id, condition, **values):
        """Check and change a pending request in one statement."""
        key = _key(request_id)
        if key is None:
            return False
        with transaction() as session:
            return (
                session.execute(
                    update(OtpChallenge)
                    .where(
                        OtpChallenge.id == key,
                        OtpChallenge.status == "pending",
                        condition,
                    )
                    .values(**values)
                ).rowcount
                > 0
            )
