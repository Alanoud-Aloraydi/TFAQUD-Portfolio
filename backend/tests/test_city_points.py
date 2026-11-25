"""The point for a patient's weather: the app's, else the city's centre
when the city is in the app's list, else none."""

from app.care.building import CITY_POINTS, city_point
from app.prayer_times import SAUDI_CITIES


def test_a_city_from_the_list_gets_its_centre():
    assert city_point(" بريدة ", None, None) == (26.3260, 43.9750)


def test_the_point_the_app_sent_wins():
    assert city_point("بريدة", 21.5, 39.2) == (21.5, 39.2)


def test_a_typed_city_has_no_point():
    assert city_point("لندن", None, None) == (None, None)
    assert city_point(None, None, None) == (None, None)


def test_every_listed_city_has_a_point():
    assert set(CITY_POINTS) == set(SAUDI_CITIES)
