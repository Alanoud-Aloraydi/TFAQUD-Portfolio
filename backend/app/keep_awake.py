"""Keeps the free API awake.

Render stops a free web service after 15 minutes without a request, and
the next person then waits about a minute for it to start again. The
scheduled scan runs every 10 minutes in its own process (`flask tick`);
before scanning it asks the API's health check (KEEP_AWAKE_URL), and that
request is enough to keep the API running."""

import logging

import httpx

log = logging.getLogger(__name__)

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
