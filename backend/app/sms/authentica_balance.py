"""The points left on an Authentica account: `GET /balance`, which
answers `{"data": {"balance": 77}}`. No sign-in waits on it, nothing here
raises, and neither the key nor the answer goes to a log."""

import http.client
import logging
import threading
from datetime import timedelta

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
