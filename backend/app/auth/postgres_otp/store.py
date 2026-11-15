"""The PostgreSQL store of sign-in codes, put together, and its claim of
a send."""

from app.auth.otp_store import (
    OtpStore,
    SendClaim,
    SendRules,
    judge_send,
    next_send_at,
)
from app.auth.postgres_otp.counts import PostgresSendCounts
from app.auth.postgres_otp.keys import lock_phone
from app.auth.postgres_otp.requests import PostgresRequests
from app.auth.postgres_otp.sends import PostgresSends
from app.auth.postgres_otp.tries import PostgresTries
from app.database import transaction
from app.models import OtpSend


class PostgresOtpStore(
    PostgresSendCounts,
    PostgresRequests,
    PostgresSends,
    PostgresTries,
    OtpStore,
):
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
