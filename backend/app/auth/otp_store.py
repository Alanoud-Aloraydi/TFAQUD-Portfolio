"""OTP metadata interface and a thread-safe implementation for unit tests.

Quota reservations include uncertain sends. Only confirmed failures release
quota. PostgreSQL provides durable storage through PostgresOtpStore.
"""

import threading
import uuid
from abc import ABC, abstractmethod
from dataclasses import dataclass, field, replace
from datetime import datetime, timedelta


class AttemptsExhausted(Exception):
    """A challenge has no remaining verification attempts."""


@dataclass(frozen=True)
class OtpRequest:
    """One sign-in attempt for a phone number: its wrong tries, whether its
    code was accepted, and until when its code is valid.
    """

    id: str
    phone: str
    created_at: datetime
    wrong_tries: int = 0
    verified_at: datetime | None = None
    status: str = "pending"
    expires_at: datetime | None = None


@dataclass(frozen=True)
class OtpSend:
    """One code sent (or reserved to send) for a request; reserved, sent or
    failed, with the device and IP that asked.
    """

    id: str
    request_id: str
    phone: str
    created_at: datetime
    sent_at: datetime | None = None
    status: str = "reserved"
    device_id: str | None = None
    client_ip: str | None = None


@dataclass(frozen=True)
class SendRules:
    """The limits on top of the phone number's own cap.

    waits: the seconds to wait after the 1st, 2nd, 3rd ... counted send to a
        number before the next one; the last one repeats. Empty: no wait.
        An attacker can then only slow the owner of a number, not lock them
        out.
    device_id, client_ip: who asks (None when unknown).
    requester_window: how far back the sends of a device or an IP count.
    max_device_sends, max_ip_sends: their caps in it (None: no cap), so one
        phone or one network cannot ask codes for many numbers.

    A known phone: a device that already signed in with this number (it
    asked for a code that was accepted) counts only its own codes for the
    number's waits and daily cap, and the IP cap does not apply to it. So
    a stranger who asks for codes for the number cannot lock its owner out.
    Every other device counts all the number's codes, the owner's too.
    """

    waits: tuple[int, ...] = ()
    device_id: str | None = None
    client_ip: str | None = None
    requester_window: timedelta = field(default=timedelta(hours=1))
    max_device_sends: int | None = None
    max_ip_sends: int | None = None


@dataclass(frozen=True)
class SendClaim:
    """A quota reservation, or why and until when another send must wait.

    reason: "phone" (the number's cap), "wait" (too soon after the last
    code), "device" or "ip" (the asker's cap). next_send_at: on a granted
    claim, the first moment the number may get one more code.
    """

    granted: bool
    request_id: str | None = None
    send_id: str | None = None
    retry_at: datetime | None = None
    reason: str | None = None
    next_send_at: datetime | None = None


def judge_send(
    now: datetime,
    phone_times: list[datetime],
    window: timedelta,
    max_sends: int,
    rules: SendRules,
    device_times: list[datetime] = (),
    ip_times: list[datetime] = (),
) -> tuple[datetime | None, str | None]:
    """When the next send must wait, and why; (None, None) when it may go.

    `phone_times` are the number's counted sends in `window`; `device_times`
    and `ip_times` the asker's in `rules.requester_window`.
    """
    # The number's cap: back when its oldest counted code leaves the window.
    phone_times = sorted(phone_times)
    if len(phone_times) >= max_sends:
        return phone_times[len(phone_times) - max_sends] + window, "phone"
    # The wait after the last code, longer with each code.
    if rules.waits and phone_times:
        wait = rules.waits[min(len(phone_times), len(rules.waits)) - 1]
        ready = phone_times[-1] + timedelta(seconds=wait)
        if now < ready:
            return ready, "wait"
    # The asking device's and IP's caps for the hour.
    for times, cap, reason in (
        (device_times, rules.max_device_sends, "device"),
        (ip_times, rules.max_ip_sends, "ip"),
    ):
        if cap is not None and len(times) >= cap:
            times = sorted(times)
            return times[len(times) - cap] + rules.requester_window, reason
    return None, None


def next_send_at(
    now: datetime,
    phone_times: list[datetime],
    window: timedelta,
    max_sends: int,
    rules: SendRules,
) -> datetime:
    """After a send at `now`, the first moment the number may get another."""
    times = sorted([*phone_times, now])
    if len(times) >= max_sends:
        return times[len(times) - max_sends] + window
    if rules.waits:
        wait = rules.waits[min(len(times), len(rules.waits)) - 1]
        return now + timedelta(seconds=wait)
    return now


class OtpStore(ABC):
    """Where sign-in requests and their sends are kept; every change is one
    atomic step, so two requests at once cannot both take the last place.
    """

    # The request with this id, or None.
    @abstractmethod
    def get_request(self, request_id: str) -> OtpRequest | None: ...

    @abstractmethod
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
        """Take one place in the phone number's limit, if there is one.

        With `rules`, the number's sends count only after its last accepted
        code (a successful sign-in starts it again), the waits between codes
        apply, and so do the caps of the asking device and IP
        (`judge_send`). A known phone (see `SendRules`) counts only its own
        sends to the number and has no IP cap.

        Nonfailed reservations created after `window_start` count toward quota.
        A reservation exactly on `window_start` is outside the window.

        `request_id=None` also creates a new request for `phone` in the same
        step; a refused claim creates nothing. Unknown or closed IDs raise
        KeyError. Exhausted resend requests raise AttemptsExhausted.
        """

    @abstractmethod
    def release_send(self, send_id: str) -> None:
        """Release quota after a confirmed delivery failure; retain history."""

    @abstractmethod
    def mark_sent(
        self, send_id: str, at: datetime, expires_at: datetime
    ) -> None:
        """Confirm delivery and update the challenge's OTP expiration."""

    @abstractmethod
    def latest_send_at(self, request_id: str) -> datetime | None:
        """Return the latest confirmed send time, or None."""

    @abstractmethod
    def claim_try(self, request_id: str, max_tries: int) -> bool:
        """Count one try on the request, if fewer than `max_tries` are counted.

        Return False without counting when the request is closed or exhausted.
        """

    @abstractmethod
    def release_try(self, request_id: str) -> None:
        """Release an undecided try without making the count negative."""

    @abstractmethod
    def mark_verified(self, request_id: str, at: datetime) -> bool:
        """Close the request because its code was accepted.

        Returns True if this call closed it, False if it was already closed or
        does not exist.
        """


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
            # A resend: the request must be this number's, still open, and have
            # tries left.
            if request_id is not None:
                request = self._requests.get(request_id)
                if (
                    request is None
                    or request.phone != phone
                    or request.status != "pending"
                ):
                    raise KeyError(request_id)
                if max_tries is not None and request.wrong_tries >= max_tries:
                    raise AttemptsExhausted()
            # The number's codes count only after its last accepted code. A
            # phone that signed in to this number before (its device) counts
            # only its own codes.
            since = window_start
            known = False
            if rules is not None:
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
            # The number's codes that count: in the window, not failed.
            phone_times = [
                s.created_at
                for s in self._sends.values()
                if s.phone == phone
                and s.created_at > since
                and s.status != "failed"
                and (not known or s.device_id == rules.device_id)
            ]
            # The asking device's and IP's codes in the last hour, for any
            # number (no IP cap for a known phone).
            device_times: list[datetime] = []
            ip_times: list[datetime] = []
            if rules is not None:
                start = now - rules.requester_window
                live = [
                    s
                    for s in self._sends.values()
                    if s.created_at > start and s.status != "failed"
                ]
                if rules.device_id:
                    device_times = [
                        s.created_at
                        for s in live
                        if s.device_id == rules.device_id
                    ]
                if rules.client_ip and not known:
                    ip_times = [
                        s.created_at
                        for s in live
                        if s.client_ip == rules.client_ip
                    ]
            # Judge every limit at once.
            window = now - window_start
            judged = rules or SendRules()
            retry_at, reason = judge_send(
                now,
                phone_times,
                window,
                max_sends,
                judged,
                device_times,
                ip_times,
            )
            if retry_at is not None:
                return SendClaim(
                    granted=False,
                    retry_at=retry_at,
                    reason=reason,
                )
            # A new request replaces the number's open one.
            if request_id is None:
                for key, request in self._requests.items():
                    if request.phone == phone and request.status == "pending":
                        self._requests[key] = replace(
                            request, status="superseded"
                        )
                request_id = uuid.uuid4().hex
                self._requests[request_id] = OtpRequest(
                    id=request_id, phone=phone, created_at=now
                )
            # Reserve the send, and say when the next code may come.
            send = OtpSend(
                id=uuid.uuid4().hex,
                request_id=request_id,
                phone=phone,
                created_at=now,
                device_id=judged.device_id,
                client_ip=judged.client_ip,
            )
            self._sends[send.id] = send
            return SendClaim(
                granted=True,
                request_id=request_id,
                send_id=send.id,
                next_send_at=next_send_at(
                    now, phone_times, window, max_sends, judged
                ),
            )

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
