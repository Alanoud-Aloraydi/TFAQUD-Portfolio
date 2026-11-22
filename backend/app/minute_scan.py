"""The scheduled scan, every minute, inside the API.

The 10-minute cron job (`flask tick`) tells a missed task up to 10 minutes
after its grace ends, and starts a container to do it. The API never
sleeps now (app/keep_awake.py), so each API process also runs the same
scan every SCAN_EVERY_SECONDS (60 on Render): a missed task is told within
about a minute. The cron job stays as the safety net, for a process that
restarted and has not served a request yet. Claims
(app/push/scheduled/claims.py) keep each push to once, however many
processes scan.

The loop starts with the process's first request, so a CLI command
(`flask db upgrade`, `flask tick`), which serves none, never starts it.
"""

import logging
import threading
import time
from datetime import timedelta

from flask import Flask

log = logging.getLogger(__name__)

_lock = threading.Lock()
_started = False


def install_minute_scan(app: Flask, database: bool) -> None:
    """Scan every SCAN_EVERY_SECONDS once a request arrives; off when it
    is 0 (development and tests) or there is no database."""
    every = app.config.get("SCAN_EVERY_SECONDS") or 0
    if not database or every <= 0:
        return

    @app.before_request
    def _start_scanning() -> None:
        global _started
        with _lock:
            if _started:
                return
            _started = True
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
