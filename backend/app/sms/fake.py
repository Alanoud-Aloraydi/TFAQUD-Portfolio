"""The fake sign-in code sender. It never contacts any provider: it makes
and checks its own 6-digit code with Authentica's rules, and keeps what it
would have texted for tests to read."""

import hmac
import logging
import secrets
import threading
from dataclasses import dataclass
from datetime import datetime, timedelta

from app.sms.base import CODE_LENGTH, SmsSender


@dataclass(frozen=True)
class SentSms:
    """One message the fake sender would have sent."""
    to: str
    message: str
    sent_at: datetime
    code: str


class FakeOutbox:
    """Reads the fake sender's `outbox`."""

    def last_message_to(self, to: str) -> SentSms | None:
        """The last message sent to `to`, or None (tests read the code from
        it).
        """
        with self._lock:
            for sms in reversed(self.outbox):
                if sms.to == to:
                    return sms
        return None


logger = logging.getLogger(__name__)

DEFAULT_VALID_SECONDS = 300


class FakeSmsSender(FakeOutbox, SmsSender):
    """Makes codes and keeps them in memory, so tests and local work sign in
    without sending any SMS.
    """
    def __init__(
        self,
        clock,
        log_body: bool = False,
        valid_seconds: int = DEFAULT_VALID_SECONDS,
    ):
        """Use `clock` for the code's lifetime; `log_body` also prints the code
        to the log (local work only).
        """
        self._clock = clock
        self._log_body = log_body
        self._valid_for = timedelta(seconds=valid_seconds)
        self._lock = threading.Lock()
        self.outbox: list[SentSms] = []
        # phone number -> (code, time it was sent). Removed when the code is
        # used.
        self._open_codes: dict[str, tuple[str, datetime]] = {}

    def send_code(self, phone: str) -> None:
        """Make a random code for `phone`, keep it, and record the message in
        the outbox.
        """
        code = f"{secrets.randbelow(10**CODE_LENGTH):0{CODE_LENGTH}d}"
        message = f"Your code is {code}"
        now = self._clock.now()
        with self._lock:
            self.outbox.append(
                SentSms(to=phone, message=message, sent_at=now, code=code)
            )
            self._open_codes[phone] = (code, now)
        if self._log_body:
            # Development only: the developer reads the code in the console.
            logger.info("FAKE SMS (not sent) to=%s message=%r", phone, message)
        else:
            logger.info("FAKE SMS (not sent) to=%s", phone)

    def check_code(self, phone: str, code: str) -> bool:
        """True only for the last code sent to `phone`, still within its
        lifetime; the code then cannot be used again.
        """
        with self._lock:
            open_code = self._open_codes.get(phone)
            if open_code is None:
                return False
            expected, sent_at = open_code
            if self._clock.now() - sent_at > self._valid_for:
                return False
            if not hmac.compare_digest(expected.encode(), code.encode()):
                return False
            del self._open_codes[phone]  # a code works once
            return True
