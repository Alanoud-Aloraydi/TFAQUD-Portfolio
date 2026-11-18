"""Authentica with backup keys: when the account of one key is close to
running out of points, codes go out with the next key at once.

Each key is its own Authentica account, and Authentica keeps a code in the
account that sent it. So a code is checked with the key that sent it first
(remembered for 15 minutes in this process), then with the others: another
worker may have sent it. The balance of each key is read at most every 5
minutes; a key that cannot say its balance counts as ready. No key, phone or
code goes to a log: a key is named by its place («key 2»)."""

import logging
import threading
from datetime import timedelta

from app.sms.authentica_balance import Balances
from app.sms.base import SmsDeliveryError, SmsSender

logger = logging.getLogger(__name__)

REMEMBER = timedelta(minutes=15)
# Answers that mean this account did not send it (a wrong key, no points):
# another account may. A server error or no answer is Authentica's own,
# and could have sent it, so it is not tried again.
REFUSED = {400, 401, 402, 403}


class AuthenticaKeys(SmsSender):
    """Sends with the first key above `low` points, in the order given."""

    def __init__(self, senders, *, low: float, clock):
        self._senders = list(senders)
        self._clock = clock
        self._lock = threading.Lock()
        self._balances = Balances(self._senders, low=low, clock=clock)
        self._sent_with: dict[str, tuple] = {}

    def send_code(self, phone: str) -> None:
        error = None
        for index in self._balances.order():
            try:
                self._senders[index].send_code(phone)
            except SmsDeliveryError as refused:
                # Nothing left either way: a refusal, or a key not called.
                if refused.status not in REFUSED and not refused.not_sent:
                    raise
                logger.warning(
                    "Authentica key %d refused send-otp (HTTP %s); "
                    "trying the next key.", index + 1, refused.status,
                )
                error = error or refused
                continue
            self._remember(phone, index)
            return
        raise error

    def check_code(self, phone: str, code: str) -> bool:
        with self._lock:
            sent = self._sent_with.get(phone)
        first = sent[1] if sent else 0
        order = [first] + [i for i in range(len(self._senders)) if i != first]
        error, refused = None, False
        for index in order:
            try:
                if self._senders[index].check_code(phone, code):
                    return True
                refused = True
            except SmsDeliveryError as failed:
                error = error or failed
        if refused or error is None:
            return False
        raise error

    def _remember(self, phone: str, index: int) -> None:
        now = self._clock.now()
        with self._lock:
            self._sent_with = {
                key: value for key, value in self._sent_with.items()
                if now - value[0] < REMEMBER
            }
            self._sent_with[phone] = (now, index)
