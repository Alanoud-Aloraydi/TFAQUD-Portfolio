"""Counters to alert on, next to the log lines.

A log line explains a failure after the fact; a counter shows it while it
happens («sign-in codes that could not be sent in the last minutes»), so
something can watch it and warn. Each server process keeps its own counts
from its start; GET /internal/metrics (with the tick secret) reads them.

The names say what happened: "sign_in.code_sent", "push.failed",
"circuit.authentica.opened". Counting never raises.
"""

import os
import threading
import time
from collections import Counter

_lock = threading.Lock()
_counts: Counter[str] = Counter()
_started_at = time.time()


def increment(name: str, by: int = 1) -> None:
    """Add `by` to the counter `name`."""
    with _lock:
        _counts[name] += by


def count(name: str) -> int:
    with _lock:
        return _counts[name]


def snapshot() -> dict:
    """Every counter of this process, and since when it counts."""
    with _lock:
        counts = dict(sorted(_counts.items()))
    return {
        "process": os.getpid(),
        "counting_since": int(_started_at),
        "counts": counts,
    }


def reset() -> None:
    """Start from zero (tests)."""
    with _lock:
        _counts.clear()
