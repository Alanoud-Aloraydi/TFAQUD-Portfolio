"""Authentica with backup keys: when the account of one key is close to
running out of points, codes go out with the next key at once.

The points left on an account come from `GET /balance`. No sign-in waits
on it, nothing here raises, and neither a key nor an answer goes to a
log."""

import http.client
import logging
import threading
from datetime import timedelta

from app.sms.base import SmsDeliveryError, SmsSender


logger = logging.getLogger(__name__)

RECHECK = timedelta(minutes=5)


def read_balance(get, base_url: str, api_key: str, timeout: float):
    """The account's balance as a number, or None when Authentica does not
    say (no answer, an error, an answer of another shape)."""
    try:
        status, body = get(
            f"{base_url}/balance", {"X-Authorization": api_key}, timeout
        )
    except (OSError, http.client.HTTPException) as error:
        logger.warning(
            "Authentica balance: no answer (%s)", type(error).__name__
        )
        return None
    data = body.get("data") if isinstance(body, dict) else None
    value = data.get("balance") if isinstance(data, dict) else None
    if status != 200 or isinstance(value, bool):
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


class Balances:
    """The balance of each key (`sender.balance()`), read at most every
    `RECHECK`, and the order to try the keys in."""

    def __init__(self, senders, *, low: float, clock):
        self._senders = senders
        self._low = low
        self._clock = clock
        self._lock = threading.Lock()
        self._known: dict[int, tuple] = {}

    def order(self) -> list[int]:
        """Those above `low` (or that cannot say) in their order, then the
        low ones, the most points first."""
        ready, low = [], []
        for index in range(len(self._senders)):
            points = self._points(index)
            if points is not None and points < self._low:
                low.append((index, points))
            else:
                ready.append(index)
        low.sort(key=lambda pair: -pair[1])
        return ready + [index for index, _ in low]

    def _points(self, index: int):
        now = self._clock.now()
        with self._lock:
            known = self._known.get(index)
        if known and now - known[0] < RECHECK:
            return known[1]
        points = self._senders[index].balance()
        if points is not None and points < self._low:
            logger.warning(
                "Authentica key %d has %s points, under %s: codes go out "
                "with another key while one has more.",
                index + 1, points, self._low,
            )
        with self._lock:
            self._known[index] = (now, points)
        return points


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
