"""What the fake sender would have texted, kept for tests to read."""

from dataclasses import dataclass
from datetime import datetime


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
