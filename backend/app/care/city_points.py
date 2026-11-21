"""Where the app's Saudi cities are, for the patient's weather on «اليوم»
(the phone's own location is never asked for). The city's centre is
close enough for its weather."""

# The app's city list (`SaudiCities.all`) with each city's latitude and
# longitude. Keep it in step with that list and with
# `app.prayer_times.cities.SAUDI_CITIES`.
CITY_POINTS: dict[str, tuple[float, float]] = {
    "الرياض": (24.7136, 46.6753),
    "جدة": (21.4858, 39.1925),
    "مكة المكرمة": (21.3891, 39.8579),
    "المدينة المنورة": (24.5247, 39.5692),
    "الدمام": (26.4207, 50.0888),
    "بريدة": (26.3260, 43.9750),
    "أبها": (18.2164, 42.5053),
    "الطائف": (21.2703, 40.4158),
    "تبوك": (28.3835, 36.5662),
    "الخبر": (26.2172, 50.1971),
    "الظهران": (26.2361, 50.0393),
    "الهفوف": (25.3800, 49.5900),
    "الجبيل": (27.0174, 49.6225),
    "حائل": (27.5114, 41.7208),
    "نجران": (17.5656, 44.2289),
    "جازان": (16.8892, 42.5511),
    "ينبع": (24.0895, 38.0618),
    "القطيف": (26.5654, 49.9964),
    "خميس مشيط": (18.3060, 42.7290),
    "الباحة": (20.0129, 41.4677),
    "عرعر": (30.9753, 41.0381),
    "سكاكا": (29.9697, 40.2064),
    "الخرج": (24.1554, 47.3346),
}


def city_point(
    city: str | None, latitude: float | None, longitude: float | None
) -> tuple[float | None, float | None]:
    """The point the app sent; else the centre of a city from the list;
    else none (a city typed by hand has no weather)."""
    if latitude is not None and longitude is not None:
        return latitude, longitude
    return CITY_POINTS.get((city or "").strip(), (None, None))
