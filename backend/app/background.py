"""Work the caller does not wait for, done after the answer is sent.

A push notification is the example: the person who sent an invitation
should not wait while Apple is called for every phone of the other person,
and the scheduled scan should not wait for one call per missed dose. Such a
job runs on a small pool of threads in the same process, with its own app
context (and so its own database session).

What this does not give: a job still waiting when the process stops is
lost. That is fine for a push (the app shows the same thing when opened),
but not for anything that must happen; that needs a real queue.

With BACKGROUND_INLINE (always in tests) a job runs at once, in the caller,
so a test sees its effect when the request returns.

`run_at` waits for a moment instead (a task put off comes again at its new
time). It is lost the same way when the process stops, so what it does is
also done by the scheduled tick, a little later. Under BACKGROUND_INLINE it
does nothing: a test calls the tick's work itself, at the time it chooses.
"""

import logging
import threading
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime

from flask import current_app

from app import metrics

log = logging.getLogger(__name__)

WORKERS = 2
# Jobs waiting at most; a job beyond is dropped and counted.
MAX_PENDING = 500

_lock = threading.Lock()
_pending = 0
_pool: ThreadPoolExecutor | None = None


def run_later(job, *args) -> None:
    """Run `job(*args)` soon, after the current request."""
    app = current_app._get_current_object()
    if app.config.get("BACKGROUND_INLINE"):
        _run(app, job, args, counted=False)
        return
    global _pending
    with _lock:
        if _pending >= MAX_PENDING:
            metrics.increment("background.dropped")
            log.warning("Too many jobs waiting: %s dropped.", job.__name__)
            return
        _pending += 1
    _executor().submit(_run, app, job, args)


def run_at(when: datetime, now: datetime, job, *args) -> None:
    """Run `job(*args)` at `when` (`now` is the time now), in this process.
    A second late is better than early: the job finds its work due."""
    app = current_app._get_current_object()
    if app.config.get("BACKGROUND_INLINE"):
        return
    delay = max(0.0, (when - now).total_seconds()) + 1
    timer = threading.Timer(delay, _run, args=(app, job, args, False))
    # A waiting timer never keeps the process from stopping.
    timer.daemon = True
    timer.start()


def _executor() -> ThreadPoolExecutor:
    """The pool of background threads, made on first use: after gunicorn
    has started the worker process, never before."""
    global _pool
    with _lock:
        if _pool is None:
            _pool = ThreadPoolExecutor(
                max_workers=WORKERS, thread_name_prefix="background"
            )
        return _pool


def _run(app, job, args, counted: bool = True) -> None:
    """Run one job inside its own app context; count and log a failure instead
    of raising it, and free its place in the queue.
    """
    global _pending
    try:
        with app.app_context():
            job(*args)
    except Exception:  # noqa: BLE001 - a job must never stop the pool
        metrics.increment("background.failed")
        log.warning("A background job failed: %s", job.__name__,
                    exc_info=True)
    finally:
        if counted:
            with _lock:
                _pending -= 1
