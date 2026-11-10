"""Fetch and cache one day's prayer times for a patient's city and zone.

A city in the app's Saudi list is asked for by its English name with the
Umm al-Qura method. Any other city (typed by hand, anywhere) is asked for
by its name as written, and the provider picks the calculation authority
nearest to it. Either way the times come in the patient's own zone, and a
timetable for another zone is refused.
"""

import json
import re
from datetime import date
from functools import lru_cache
from urllib.error import URLError
from urllib.parse import urlencode
from urllib.request import urlopen

from app.errors import ServiceUnavailable

# The app's Saudi city list (`SaudiCities.all`), with the English name the
# provider knows each by. Keep the two in step.
_SAUDI_CITIES = {
    "الرياض": "Riyadh",
    "جدة": "Jeddah",
    "مكة المكرمة": "Makkah",
    "المدينة المنورة": "Madinah",
    "الدمام": "Dammam",
    "بريدة": "Buraidah",
    "أبها": "Abha",
    "الطائف": "Taif",
    "تبوك": "Tabuk",
    "الخبر": "Khobar",
    "الظهران": "Dhahran",
    "الهفوف": "Al Hofuf",
    "الجبيل": "Jubail",
    "حائل": "Hail",
    "نجران": "Najran",
    "جازان": "Jazan",
    "ينبع": "Yanbu",
    "القطيف": "Qatif",
    "خميس مشيط": "Khamis Mushait",
    "الباحة": "Al Bahah",
    "عرعر": "Arar",
    "سكاكا": "Sakaka",
    "الخرج": "Al Kharj",
}
_UMM_AL_QURA = 4
_PRAYERS = ("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")
_TIME = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")


def prayer_times_for(city: str, zone: str, day: date) -> dict[str, str]:
    """Return the five times of `day` at `city`, as wall clock in `zone`;
    cache only successful city-days."""
    saudi = _SAUDI_CITIES.get(city)
    if saudi:
        path = "timingsByCity"
        query = (("city", saudi), ("country", "SA"),
                 ("method", str(_UMM_AL_QURA)))
    else:
        path, query = "timingsByAddress", (("address", city),)
    return _fetch_day(path, query, zone, day.isoformat())


@lru_cache(maxsize=256)
def _fetch_day(
    path: str, query: tuple[tuple[str, str], ...], zone: str, day: str
) -> dict[str, str]:
    """Keep a place-day's timetable until it leaves the bounded cache."""
    formatted = date.fromisoformat(day).strftime("%d-%m-%Y")
    params = urlencode(query + (("timezonestring", zone),))
    url = f"https://api.aladhan.com/v1/{path}/{formatted}?{params}"
    try:
        with urlopen(url, timeout=8) as response:
            payload = json.loads(response.read(65537))
        if payload.get("code") != 200:
            raise ValueError("Unexpected provider status")
        data = payload["data"]
        method = dict(query).get("method")
        if method and str(data["meta"]["method"]["id"]) != method:
            raise ValueError("Unexpected calculation method")
        if data["meta"]["timezone"] != zone:
            raise ValueError("Unexpected timetable timezone")
        if data["date"]["gregorian"]["date"] != formatted:
            raise ValueError("Unexpected timetable date")
        times = {name: data["timings"][name] for name in _PRAYERS}
        if not all(isinstance(value, str) and _TIME.fullmatch(value)
                   for value in times.values()):
            raise ValueError("Invalid prayer time")
        return times
    except (URLError, OSError, ValueError, KeyError, TypeError) as error:
        raise ServiceUnavailable(code="prayer_times_unavailable") from error
