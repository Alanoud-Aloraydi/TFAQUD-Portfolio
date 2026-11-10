"""A circuit breaker for the services outside our server.

Authentica (sign-in codes), Aladhan (prayer times) and Apple (push) each
have a time limit on every call. A time limit alone still waits the whole
limit on every call while a service is down: ten sign-ins wait ten seconds
each, and one scheduled scan waits ten seconds per phone. After a few
failures in a row the breaker "opens" and the calls fail at once, without
reaching the service, for a short cool-down. The first call after it is a
trial: a success closes the breaker, a failure opens it again.

Each server process has its own breakers (gunicorn runs one or two). Never
put one around our own database: a slow query would become an outage.
"""

import logging
import threading
import time

from app import metrics

log = logging.getLogger(__name__)

DEFAULT_FAILURES = 3
DEFAULT_COOL_DOWN_SECONDS = 60.0

_all: list["CircuitBreaker"] = []


class CircuitBreaker:
    """Opens after `failures` failures in a row, for `cool_down` seconds."""

    def __init__(
        self,
        name: str,
        *,
        failures: int = DEFAULT_FAILURES,
        cool_down: float = DEFAULT_COOL_DOWN_SECONDS,
        clock=time.monotonic,
    ):
        """A closed breaker for the service `name`, kept in the list
        `reset_all` closes.
        """
        self.name = name
        self._threshold = failures
        self._cool_down = cool_down
        self._clock = clock
        self._lock = threading.Lock()
        self._failures = 0
        self._open_until = 0.0
        _all.append(self)

    def allow(self) -> bool:
        """Whether to call the service now. False while open: the caller
        answers at once, as if the service had failed."""
        with self._lock:
            refused = self._clock() < self._open_until
        if refused:
            metrics.increment(f"circuit.{self.name}.refused")
        return not refused

    def record_success(self) -> None:
        """The service answered: count again from zero."""
        with self._lock:
            self._failures = 0
            self._open_until = 0.0

    def record_failure(self) -> None:
        """No answer, or an answer that says the service is sick."""
        with self._lock:
            self._failures += 1
            if self._failures < self._threshold:
                return
            self._open_until = self._clock() + self._cool_down
        metrics.increment(f"circuit.{self.name}.opened")
        log.warning(
            "%s failed %s times in a row: not called for %s seconds.",
            self.name,
            self._threshold,
            int(self._cool_down),
        )

    def reset(self) -> None:
        """Close the breaker and forget its failures."""
        self.record_success()


def reset_all() -> None:
    """Close every breaker (tests start each case with all closed)."""
    for breaker in _all:
        breaker.reset()
