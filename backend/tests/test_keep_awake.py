"""The scan's request that keeps the free API awake."""

import httpx

from app.background import keep_awake


class Client:
    """Keeps each address asked; raises `error` when given one."""

    def __init__(self, error=None):
        self.asked = []
        self.error = error

    def get(self, url, timeout):
        self.asked.append(url)
        if self.error is not None:
            raise self.error


def test_asks_the_health_check_once():
    client = Client()

    keep_awake("https://api.test/health", client)

    assert client.asked == ["https://api.test/health"]


def test_asks_nothing_without_an_address():
    client = Client()

    keep_awake(None, client)

    assert client.asked == []


def test_a_slow_or_missing_answer_never_stops_the_scan():
    keep_awake("https://api.test/health", Client(httpx.ReadTimeout("slow")))
    keep_awake("https://api.test/health", Client(httpx.ConnectError("no")))
