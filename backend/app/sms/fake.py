"""The fake sign-in code sender. It never contacts any provider.

It makes and checks its own 6-digit code, with the rules that Authentica showed in
the tests of TFQD-12 (docs/api-contracts.md, section 8):

  - the code is valid for `valid_seconds` (300) after it is sent;
  - a code is accepted once; the same code a second time is refused;
  - a wrong code, a code of the wrong length and an expired code are all just
    "False". There is no difference between them;
  - wrong tries are never blocked (Authentica did not block any), so counting
    them is the job of our server.

One rule is a choice, not a finding: a new code replaces the old code of the
same phone number. Whether Authentica does the same is test 9 of the test guide.

Every message "sent" is kept in `outbox`, so a test can read the code that would
have been texted to the user.
"""

import hmac
import logging
import secrets
import threading
from dataclasses import dataclass
from datetime import datetime, timedelta

from app.sms.base import CODE_LENGTH, SmsSender

logger = logging.getLogger(__name__)

DEFAULT_VALID_SECONDS = 300


@dataclass(frozen=True)
class SentSms:
    to: str
    message: str
    sent_at: datetime
    code: str


class FakeSmsSender(SmsSender):
    def __init__(
        self,
        clock,
        log_body: bool = False,
        valid_seconds: int = DEFAULT_VALID_SECONDS,
    ):
        self._clock = clock
        self._log_body = log_body
        self._valid_for = timedelta(seconds=valid_seconds)
        self._lock = threading.Lock()
        self.outbox: list[SentSms] = []
        # phone number -> (code, time it was sent). Removed when the code is used.
        self._open_codes: dict[str, tuple[str, datetime]] = {}

    def send_code(self, phone: str) -> None:
        code = f"{secrets.randbelow(10**CODE_LENGTH):0{CODE_LENGTH}d}"
        message = f"Your code is {code}"
        now = self._clock.now()
        with self._lock:
            self.outbox.append(SentSms(to=phone, message=message, sent_at=now, code=code))
            self._open_codes[phone] = (code, now)
        if self._log_body:
            # Development only: lets the developer read the code in the console.
            logger.info("FAKE SMS (not sent) to=%s message=%r", phone, message)
        else:
            logger.info("FAKE SMS (not sent) to=%s", phone)

    def check_code(self, phone: str, code: str) -> bool:
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

    def last_message_to(self, to: str) -> SentSms | None:
        with self._lock:
            for sms in reversed(self.outbox):
                if sms.to == to:
                    return sms
        return None
