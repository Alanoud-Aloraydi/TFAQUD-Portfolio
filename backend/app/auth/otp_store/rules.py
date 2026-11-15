"""The limits on sending codes, and the answer to a send asked for."""

from dataclasses import dataclass, field
from datetime import datetime, timedelta


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
