"""The sign-in code store in memory, behind one lock: for tests and for a
local server without a database."""

import threading
from datetime import datetime

from app.auth.otp_store.interface import OtpStore
from app.auth.otp_store.judging import judge_send, next_send_at
from app.auth.otp_store.memory_counts import MemorySendCounts
from app.auth.otp_store.memory_sends import MemorySends
from app.auth.otp_store.memory_tries import MemoryTries
from app.auth.otp_store.records import OtpRequest, OtpSend
from app.auth.otp_store.rules import SendClaim, SendRules


class InMemoryOtpStore(MemorySendCounts, MemorySends, MemoryTries, OtpStore):
    """The requests and sends in memory, behind one lock: for tests and for a
    local server without a database.
    """

    def __init__(self):
        """No requests and no sends yet."""
        self._lock = threading.Lock()
        self._requests: dict[str, OtpRequest] = {}
        self._sends: dict[str, OtpSend] = {}

    def get_request(self, request_id: str) -> OtpRequest | None:
        """The request with this id, or None."""
        with self._lock:
            return self._requests.get(request_id)

    def claim_send(
        self,
        request_id: str | None,
        phone: str,
        now: datetime,
        window_start: datetime,
        max_sends: int,
        *,
        max_tries: int | None = None,
        rules: SendRules | None = None,
    ) -> SendClaim:
        """See OtpStore.claim_send: judge the limits, then reserve the send
        (and create the request when there is none).
        """
        with self._lock:
            if request_id is not None:
                self._check_resend(request_id, phone, max_tries)
            judged = rules or SendRules()
            since, known = self._counted_since(phone, window_start, rules)
            phone_times = self._phone_times(phone, since, known, judged)
            device_times, ip_times = self._requester_times(now, rules, known)
            # Judge every limit at once.
            window = now - window_start
            retry_at, reason = judge_send(
                now, phone_times, window, max_sends, judged, device_times,
                ip_times,
            )
            if retry_at is not None:
                return SendClaim(
                    granted=False, retry_at=retry_at, reason=reason
                )
            if request_id is None:
                request_id = self._open_request(phone, now)
            send = self._reserve(request_id, phone, now, judged)
            return SendClaim(
                granted=True,
                request_id=request_id,
                send_id=send.id,
                next_send_at=next_send_at(
                    now, phone_times, window, max_sends, judged
                ),
            )
