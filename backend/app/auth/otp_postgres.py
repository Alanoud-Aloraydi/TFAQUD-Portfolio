"""The PostgreSQL store of sign-in codes: requests, wrong tries and accepted
codes, each change made under a lock on the phone number."""

from uuid import uuid4

from sqlalchemy import update

from app.auth.otp_postgres_sends import PostgresSends, lock_phone, request_key
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
from app.models import OtpRequest as OtpRequestRow, OtpSend


class PostgresOtpStore(PostgresSends, OtpStore):
    """Own short transactions; no provider call holds a database lock."""

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
            lock_phone(session, phone)
            row = (
                self._open_request(session, request_id, phone, now, max_tries)
                if request_id is not None
                else None
            )
            since, known = self._counted_since(
                session, phone, window_start, rules
            )
            phone_times = self._phone_times(
                session, phone, since, known, judged
            )
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
            send = self._reserve(session, row, now, judged)
            return SendClaim(
                granted=True,
                request_id=row.id.hex,
                send_id=send.id.hex,
                next_send_at=next_send_at(
                    now, phone_times, window, max_sends, judged
                ),
            )

    # Reads, opens and updates sign-in requests.
    def get_request(self, request_id):
        """The request with this id, or None (also for an id that is not a
        UUID).
        """
        # An id that is not a UUID is no request.
        key = request_key(request_id)
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

    @staticmethod
    def _open_request(session, request_id, phone, now, max_tries):
        """Recheck a resend under lock, or supersede older open requests."""
        # A resend: this number's open request, locked, with tries left.
        if request_id is not None:
            key = request_key(request_id)
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

    @staticmethod
    def _update_request(request_id, condition, **values):
        """Check and change a pending request in one statement."""
        key = request_key(request_id)
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

    # Counts the tries of a request and marks it verified.
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
