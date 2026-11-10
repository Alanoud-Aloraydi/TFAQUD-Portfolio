"""The circuit breaker, the counters and the work after the answer."""

import threading
from datetime import datetime, timezone

import pytest
from flask import Flask, current_app

from app import background, create_app, metrics
from app.resilience import CircuitBreaker


class Clock:
    """Seconds that move only when the test says."""

    def __init__(self):
        self.now = 1000.0

    def __call__(self):
        return self.now


@pytest.fixture
def clock():
    return Clock()


def breaker(clock, **kwargs):
    return CircuitBreaker("service", clock=clock, **kwargs)


# ---- the circuit breaker --------------------------------------------------


def test_a_closed_breaker_lets_every_call_through(clock):
    service = breaker(clock)

    service.record_failure()
    service.record_failure()

    assert service.allow()


def test_three_failures_in_a_row_open_it_for_a_minute(clock):
    service = breaker(clock)

    for _ in range(3):
        service.record_failure()

    assert not service.allow()
    assert metrics.count("circuit.service.opened") == 1
    assert metrics.count("circuit.service.refused") == 1
    clock.now += 59
    assert not service.allow()
    clock.now += 1
    assert service.allow()


def test_a_success_counts_again_from_zero(clock):
    service = breaker(clock)

    service.record_failure()
    service.record_failure()
    service.record_success()
    service.record_failure()
    service.record_failure()

    assert service.allow()


def test_after_the_cool_down_one_failure_opens_it_again(clock):
    service = breaker(clock, failures=2, cool_down=10)
    service.record_failure()
    service.record_failure()
    clock.now += 10

    # The trial call fails.
    assert service.allow()
    service.record_failure()

    assert not service.allow()
    assert metrics.count("circuit.service.opened") == 2


def test_after_the_cool_down_a_success_closes_it(clock):
    service = breaker(clock, failures=2, cool_down=10)
    service.record_failure()
    service.record_failure()
    clock.now += 10

    service.record_success()
    service.record_failure()

    assert service.allow()


# ---- the counters ---------------------------------------------------------


def test_the_counters_say_what_and_since_when():
    metrics.increment("push.sent")
    metrics.increment("push.sent")
    metrics.increment("push.failed", by=3)

    snapshot = metrics.snapshot()

    assert snapshot["counts"] == {"push.failed": 3, "push.sent": 2}
    assert isinstance(snapshot["process"], int)
    assert isinstance(snapshot["counting_since"], int)


# ---- the work after the answer ---------------------------------------------


def test_tests_run_the_work_at_once():
    app = create_app("testing")
    done = []

    with app.app_context():
        background.run_later(done.append, "pushed")

    assert done == ["pushed"]


def test_outside_tests_the_work_runs_after_the_answer_in_its_own_context():
    app = Flask(__name__)
    app.config["BACKGROUND_INLINE"] = False
    release = threading.Event()
    finished = threading.Event()
    seen = {}

    def job(value):
        release.wait(5)
        seen["app"] = current_app._get_current_object()
        seen["value"] = value
        finished.set()

    with app.app_context():
        background.run_later(job, 7)
    # The caller went on before the job finished.
    assert "value" not in seen
    release.set()

    assert finished.wait(5)
    assert seen == {"app": app, "value": 7}


def test_a_failing_job_is_counted_and_stops_nothing():
    app = create_app("testing")

    def broken():
        raise RuntimeError("Apple said no")

    with app.app_context():
        background.run_later(broken)
        background.run_later(metrics.increment, "after")

    assert metrics.count("background.failed") == 1
    assert metrics.count("after") == 1


def test_a_job_for_later_waits_for_its_moment_in_its_own_context():
    app = Flask(__name__)
    app.config["BACKGROUND_INLINE"] = False
    finished = threading.Event()
    seen = {}
    now = datetime(2026, 11, 11, 9, tzinfo=timezone.utc)

    def job(value):
        seen["app"] = current_app._get_current_object()
        seen["value"] = value
        finished.set()

    with app.app_context():
        # Already due: it still runs after the caller, a second late.
        background.run_at(now, now, job, 3)
    assert "value" not in seen

    assert finished.wait(5)
    assert seen == {"app": app, "value": 3}


def test_tests_leave_a_job_for_later_to_the_tick():
    app = create_app("testing")
    done = []
    now = datetime(2026, 11, 11, 9, tzinfo=timezone.utc)

    with app.app_context():
        background.run_at(now, now, done.append, "reminded")

    assert done == []
