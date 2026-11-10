"""GET /internal/metrics: the counters, for the scheduler's secret only."""

import pytest

from app import create_app, metrics

SECRET = "s" * 40


@pytest.fixture
def client():
    app = create_app("testing", overrides={"TICK_SECRET": SECRET})
    return app.test_client()


@pytest.mark.parametrize("headers", [{}, {"X-Tick-Secret": "wrong"}])
def test_without_the_secret_there_is_nothing_here(client, headers):
    assert client.get("/internal/metrics", headers=headers).status_code == 404


def test_without_a_secret_set_there_is_nothing_here():
    client = create_app("testing").test_client()

    answer = client.get("/internal/metrics", headers={"X-Tick-Secret": ""})

    assert answer.status_code == 404


def test_with_the_secret_the_counters_of_this_process(client):
    metrics.increment("sign_in.code_not_sent")

    answer = client.get("/internal/metrics", headers={"X-Tick-Secret": SECRET})

    assert answer.status_code == 200
    assert answer.headers["Cache-Control"] == "no-store"
    assert answer.get_json()["counts"] == {"sign_in.code_not_sent": 1}
