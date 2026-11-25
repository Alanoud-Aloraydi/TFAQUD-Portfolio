"""The sign-in code store in memory, behind one lock: for tests and for a
local server without a database."""

import threading
import uuid
from dataclasses import replace
from datetime import datetime

from app.auth.otp_store import (
    AttemptsExhausted,
    OtpRequest,
    OtpSend,
    OtpStore,
    SendClaim,
    SendRules,
    judge_send,
    next_send_at,
)


class InMemoryOtpStore(OtpStore):
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

    # Which codes count against a number, a device and an IP.
    def _check_resend(
        self, request_id: str, phone: str, max_tries: int | None
    ) -> None:
        """A resend: the request must be this number's, still open, and have
        tries left."""
        request = self._requests.get(request_id)
        if (
            request is None
            or request.phone != phone
            or request.status != "pending"
        ):
            raise KeyError(request_id)
        if max_tries is not None and request.wrong_tries >= max_tries:
            raise AttemptsExhausted()

    def _counted_since(
        self, phone: str, window_start: datetime, rules: SendRules | None
    ) -> tuple[datetime, bool]:
        """Since when the number's codes count, and whether the asking phone
        signed in to it before. The codes count only after the number's last
        accepted code; a phone that signed in to it before (its device)
        counts only its own codes."""
        if rules is None:
            return window_start, False
        since = window_start
        verified = [
            r.verified_at
            for r in self._requests.values()
            if r.phone == phone and r.verified_at is not None
        ]
        if verified:
            since = max(since, max(verified))
        known = bool(rules.device_id) and any(
            s.phone == phone
            and s.device_id == rules.device_id
            and self._requests[s.request_id].verified_at is not None
            for s in self._sends.values()
        )
        return since, known

    def _phone_times(
        self, phone: str, since: datetime, known: bool, rules: SendRules
    ) -> list[datetime]:
        """The number's codes that count: in the window, not failed."""
        return [
            s.created_at
            for s in self._sends.values()
            if s.phone == phone
            and s.created_at > since
            and s.status != "failed"
            and (not known or s.device_id == rules.device_id)
        ]

    def _requester_times(
        self, now: datetime, rules: SendRules | None, known: bool
    ) -> tuple[list[datetime], list[datetime]]:
        """The asking device's and IP's codes in the last hour, for any
        number (no IP cap for a known phone)."""
        device_times: list[datetime] = []
        ip_times: list[datetime] = []
        if rules is None:
            return device_times, ip_times
        start = now - rules.requester_window
        live = [
            s
            for s in self._sends.values()
            if s.created_at > start and s.status != "failed"
        ]
        if rules.device_id:
            device_times = [
                s.created_at for s in live if s.device_id == rules.device_id
            ]
        if rules.client_ip and not known:
            ip_times = [
                s.created_at for s in live if s.client_ip == rules.client_ip
            ]
        return device_times, ip_times

    # Opens requests and keeps the state of each send.
    def _open_request(self, phone: str, now: datetime) -> str:
        """A new request for the number, replacing its open one."""
        for key, request in self._requests.items():
            if request.phone == phone and request.status == "pending":
                self._requests[key] = replace(request, status="superseded")
        request_id = uuid.uuid4().hex
        self._requests[request_id] = OtpRequest(
            id=request_id, phone=phone, created_at=now
        )
        return request_id

    def _reserve(
        self, request_id: str, phone: str, now: datetime, rules: SendRules
    ) -> OtpSend:
        """Reserve the send for the request."""
        send = OtpSend(
            id=uuid.uuid4().hex,
            request_id=request_id,
            phone=phone,
            created_at=now,
            device_id=rules.device_id,
            client_ip=rules.client_ip,
        )
        self._sends[send.id] = send
        return send

    def release_send(self, send_id: str) -> None:
        """Give the reserved place back: the provider refused, so no code left.
        """
        with self._lock:
            send = self._sends.get(send_id)
            if send is not None and send.status == "reserved":
                self._sends[send_id] = replace(send, status="failed")

    def mark_sent(self, send_id, at, expires_at):
        """Mark the send as sent, and keep the request open until the newest
        code's end.
        """
        with self._lock:
            send = self._sends.get(send_id)
            if send is None or send.status != "reserved":
                return
            self._sends[send_id] = replace(send, status="sent", sent_at=at)
            request = self._requests[send.request_id]
            if request.status == "pending":
                expiration = max(request.expires_at or expires_at, expires_at)
                self._requests[request.id] = replace(
                    request, expires_at=expiration
                )

    def latest_send_at(self, request_id: str) -> datetime | None:
        """When the request's last code was sent, or None."""
        with self._lock:
            times = [
                s.sent_at
                for s in self._sends.values()
                if s.request_id == request_id and s.status == "sent"
            ]
            return max(times) if times else None

    # Counts the tries of a request and marks it verified.
    def claim_try(self, request_id: str, max_tries: int) -> bool:
        """Count one try on an open request with tries left; False otherwise.
        """
        with self._lock:
            request = self._requests.get(request_id)
            if (
                request is None
                or request.status != "pending"
                or request.wrong_tries >= max_tries
            ):
                return False
            self._requests[request_id] = replace(
                request, wrong_tries=request.wrong_tries + 1
            )
            return True

    def release_try(self, request_id: str) -> None:
        """Take back a try the provider could not decide."""
        with self._lock:
            request = self._requests.get(request_id)
            if (
                request is not None
                and request.status == "pending"
                and request.wrong_tries > 0
            ):
                self._requests[request_id] = replace(
                    request, wrong_tries=request.wrong_tries - 1
                )

    def mark_verified(self, request_id: str, at: datetime) -> bool:
        """Close an open request as accepted; False when it was already closed
        or unknown.
        """
        with self._lock:
            request = self._requests.get(request_id)
            if request is None or request.status != "pending":
                return False
            self._requests[request_id] = replace(
                request, status="verified", verified_at=at
            )
            return True
