"""Work outside the request.

Work the caller does not wait for runs after the answer is sent (a push
notification, for example). The scheduled scan runs every minute inside
the API, and a ping keeps the free API awake."""

import logging
import threading
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta

import httpx
from flask import Flask, current_app

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


# A sleeping API takes up to a minute to answer; the request wakes it even
# when the answer comes after this wait.
_WAIT_SECONDS = 30


def keep_awake(url: str | None, client=None) -> None:
    """Ask `url` once, if it is set; never raises, so the scan always
    runs."""
    if not url:
        return
    try:
        (client or httpx).get(url, timeout=_WAIT_SECONDS)
    except Exception:  # noqa: BLE001 - the scan must still run
        log.info("The keep-awake request got no answer in time.")


_scan_lock = threading.Lock()

_scan_started = False


def install_minute_scan(app: Flask, database: bool) -> None:
    """Scan every SCAN_EVERY_SECONDS once a request arrives; off when it
    is 0 (development and tests) or there is no database."""
    every = app.config.get("SCAN_EVERY_SECONDS") or 0
    if not database or every <= 0:
        return

    @app.before_request
    def _start_scanning() -> None:
        global _scan_started
        with _scan_lock:
            if _scan_started:
                return
            _scan_started = True
        threading.Thread(
            target=_scan_forever,
            args=(app, every),
            name="minute-scan",
            daemon=True,
        ).start()


def _scan_forever(app: Flask, every: int) -> None:
    """Scan, wait, repeat; a failed scan is logged, and the next one comes
    a minute later."""
    from app.extensions import get_clock
    from app.push.scheduled import run_tick

    while True:
        time.sleep(every)
        try:
            with app.app_context():
                # The reminders due before the next scan get a timer each,
                # so they come on their minute (app/push/scheduled/
                # reminders).
                run_tick(get_clock().now(), timedelta(seconds=every))
        except Exception:  # noqa: BLE001 - the loop must keep going
            log.exception("The minute scan failed; the next one retries.")
