"""The fake SMS sender. It never contacts any provider.

Every message "sent" is kept in `outbox`, so a test can read the code that
would have been texted to the user.
"""

import logging
import threading
from dataclasses import dataclass
from datetime import datetime

from app.sms.base import SmsSender

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class SentSms:
    to: str
    message: str
    sent_at: datetime


class FakeSmsSender(SmsSender):
    def __init__(self, clock, log_body: bool = False):
        self._clock = clock
        self._log_body = log_body
        self._lock = threading.Lock()
        self.outbox: list[SentSms] = []

    def send(self, to: str, message: str) -> None:
        with self._lock:
            self.outbox.append(SentSms(to=to, message=message, sent_at=self._clock.now()))
        if self._log_body:
            # Development only: lets the developer read the OTP in the console.
            logger.info("FAKE SMS (not sent) to=%s message=%r", to, message)
        else:
            logger.info("FAKE SMS (not sent) to=%s", to)

    def last_message_to(self, to: str) -> SentSms | None:
        with self._lock:
            for sms in reversed(self.outbox):
                if sms.to == to:
                    return sms
        return None
