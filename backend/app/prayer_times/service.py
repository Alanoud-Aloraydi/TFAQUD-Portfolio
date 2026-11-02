"""Fetch and cache one day's prayer times by Saudi city."""

import json
import re
from datetime import date
from functools import lru_cache
from urllib.error import URLError
from urllib.parse import urlencode
from urllib.request import urlopen

from app.errors import ServiceUnavailable

_CITY_NAMES = {
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
_PRAYERS = ("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")
_TIME = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")


def prayer_times_for(city: str, day: date) -> dict[str, str]:
    """Return five Umm al-Qura times; cache only successful city-days."""
    if city not in _CITY_NAMES:
        raise ServiceUnavailable(code="prayer_times_unavailable")
    return _fetch_day(_CITY_NAMES[city], day.isoformat())


@lru_cache(maxsize=256)
def _fetch_day(city: str, day: str) -> dict[str, str]:
    """Keep a date's timetable until it leaves the bounded cache."""
    formatted = date.fromisoformat(day).strftime("%d-%m-%Y")
    query = urlencode({"city": city, "country": "SA", "method": 4})
    url = f"https://api.aladhan.com/v1/timingsByCity/{formatted}?{query}"
    try:
        with urlopen(url, timeout=8) as response:
            payload = json.loads(response.read(65537))
        if payload.get("code") != 200:
            raise ValueError("Unexpected provider status")
        data = payload["data"]
        if data["meta"]["method"]["id"] != 4:
            raise ValueError("Unexpected calculation method")
        if data["meta"]["timezone"] != "Asia/Riyadh":
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
