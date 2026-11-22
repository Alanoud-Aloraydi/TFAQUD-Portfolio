"""The scan the API runs every minute (app/minute_scan.py)."""

import threading
from datetime import timedelta

import pytest
from flask import Flask

from app import minute_scan


class Stop(Exception):
    """Ends the endless loop in a test."""


@pytest.fixture(autouse=True)
def not_started(monkeypatch):
    monkeypatch.setattr(minute_scan, "_started", False)


def flask_app(every):
    app = Flask(__name__)
    app.config["SCAN_EVERY_SECONDS"] = every
    app.add_url_rule("/", "home", lambda: "")
    return app


def test_the_first_request_starts_one_loop(monkeypatch):
    loops = []
    started = threading.Event()

    def loop(app, every):
        loops.append(every)
        started.set()

    monkeypatch.setattr(minute_scan, "_scan_forever", loop)
    app = flask_app(60)
    minute_scan.install_minute_scan(app, database=True)

    client = app.test_client()
    client.get("/")
    client.get("/")

    assert started.wait(2)
    assert loops == [60]


@pytest.mark.parametrize("every, database", [(0, True), (60, False)])
def test_off_without_a_database_or_an_interval(monkeypatch, every, database):
    loops = []
    monkeypatch.setattr(minute_scan, "_scan_forever", loops.append)
    app = flask_app(every)
    minute_scan.install_minute_scan(app, database=database)

    app.test_client().get("/")

    assert loops == []


def test_a_failed_scan_does_not_stop_the_next(monkeypatch):
    scans = []
    naps = []

    def scan(now, ahead):
        scans.append((now, ahead))
        if len(scans) == 1:
            raise RuntimeError("database away")

    def nap(seconds):
        naps.append(seconds)
        if len(naps) == 3:
            raise Stop

    monkeypatch.setattr("app.push.scheduled.run_tick", scan)
    monkeypatch.setattr("app.extensions.get_clock", lambda: Clock())
    monkeypatch.setattr(minute_scan.time, "sleep", nap)

    with pytest.raises(Stop):
        minute_scan._scan_forever(flask_app(60), 60)

    assert naps == [60, 60, 60]
    assert len(scans) == 2
    # The reminders due before the next scan get their timers.
    assert scans[1] == ("now", timedelta(seconds=60))


class Clock:
    def now(self):
        return "now"
