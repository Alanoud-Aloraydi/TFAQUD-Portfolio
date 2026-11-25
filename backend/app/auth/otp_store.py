"""What every store of sign-in codes keeps and does: a request for a code
to a phone, each send of it, the limits on sending, and how a send is
judged against them.

A send is reserved before the SMS goes, so a quota holds even when the
provider's answer is uncertain; only a confirmed failure releases it."""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
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
