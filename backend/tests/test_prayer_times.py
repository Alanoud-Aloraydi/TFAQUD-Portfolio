"""Provider parsing, city and zone choice and daily cache for prayer
times."""

import json
from datetime import date
from io import BytesIO
from urllib.parse import parse_qs, urlparse

import pytest

from app.errors import ServiceUnavailable
from app.prayer_times import service

RIYADH = "Asia/Riyadh"


def _payload(day: str, method: int = 4,
             timezone: str = "Asia/Riyadh") -> bytes:
    """Build a minimal documented AlAdhan daily response."""
    return json.dumps({
        "code": 200,
        "data": {
            "date": {"gregorian": {"date": day}},
            "meta": {"method": {"id": method},
                     "timezone": timezone},
            "timings": {
                "Fajr": "04:41",
                "Dhuhr": "11:37",
                "Asr": "14:49",
                "Maghrib": "17:13",
                "Isha": "18:43",
            },
        },
    }).encode()


def test_selected_city_and_date_are_sent_once(monkeypatch):
    """Reuse one city-day but fetch a changed city or date separately."""
    service._fetch_day.cache_clear()
    urls = []

    def fake_open(url, timeout):
        urls.append(url)
        assert timeout == 8
        day = url.rsplit("/", 1)[-1].split("?", 1)[0]
        return BytesIO(_payload(day))

    monkeypatch.setattr(service, "urlopen", fake_open)
    first = service.prayer_times_for("بريدة", RIYADH, date(2026, 11, 2))
    assert first["Fajr"] == "04:41"
    assert service.prayer_times_for(
        "بريدة", RIYADH, date(2026, 11, 2)
    ) == first
    service.prayer_times_for("الرياض", RIYADH, date(2026, 11, 2))
    service.prayer_times_for("بريدة", RIYADH, date(2026, 11, 3))
    assert len(urls) == 3
    assert "/timingsByCity/" in urls[0]
    query = parse_qs(urlparse(urls[0]).query)
    assert query == {"city": ["Buraidah"], "country": ["SA"],
                     "method": ["4"], "timezonestring": [RIYADH]}
    service._fetch_day.cache_clear()


def test_invalid_provider_method_is_not_cached(monkeypatch):
    """A wrong calculation method cannot be shown as Umm al-Qura."""
    service._fetch_day.cache_clear()
    calls = []

    def fake_open(url, timeout):
        calls.append(url)
        return BytesIO(_payload("02-11-2026", method=3))

    monkeypatch.setattr(service, "urlopen", fake_open)
    for _ in range(2):
        with pytest.raises(ServiceUnavailable) as error:
            service.prayer_times_for("الرياض", RIYADH, date(2026, 11, 2))
        assert error.value.code == "prayer_times_unavailable"
    assert len(calls) == 2
    service._fetch_day.cache_clear()


def test_a_city_outside_saudi_arabia_is_asked_for_in_its_zone(
    monkeypatch,
):
    """A typed city is found by its name, never labelled Saudi, and its
    times come in the patient's zone with the provider's method."""
    service._fetch_day.cache_clear()
    urls = []

    def fake_open(url, timeout):
        urls.append(url)
        return BytesIO(
            _payload("02-11-2026", method=3, timezone="Europe/London")
        )

    monkeypatch.setattr(service, "urlopen", fake_open)
    times = service.prayer_times_for(
        "لندن", "Europe/London", date(2026, 11, 2)
    )
    assert times["Isha"] == "18:43"
    assert "/timingsByAddress/02-11-2026?" in urls[0]
    assert parse_qs(urlparse(urls[0]).query) == {
        "address": ["لندن"], "timezonestring": ["Europe/London"],
    }
    service._fetch_day.cache_clear()


def test_wrong_timezone_is_not_cached(monkeypatch):
    """Reject a timetable that was calculated for another timezone."""
    service._fetch_day.cache_clear()

    def fake_open(url, timeout):
        return BytesIO(_payload("02-11-2026", timezone="Europe/London"))

    monkeypatch.setattr(service, "urlopen", fake_open)
    with pytest.raises(ServiceUnavailable):
        service.prayer_times_for("الرياض", RIYADH, date(2026, 11, 2))
    service._fetch_day.cache_clear()
