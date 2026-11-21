"""A circle whose city is in the app's list gets the city's point, so the
patient's weather shows on «اليوم», and a new city replaces it."""

import pytest

from app.database import db
from integration_tests.helpers import Api

SELF = {"name": "My care", "birth_date": "1954-06-05", "city": "بريدة"}


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release request transactions before the next test truncates tables."""
    yield
    db.session.remove()


def test_a_listed_city_gives_the_circle_its_point(
    database_app, database, account
):
    api = Api(database_app, account())

    created = api.post("/api/v1/circles/self", SELF)

    assert created.status_code == 201, created.get_json()
    [home] = api.get("/api/v1/home").json["care_circles"]
    assert (home["latitude"], home["longitude"]) == (26.3260, 43.9750)


def test_a_typed_city_leaves_it_without_one(database_app, database, account):
    api = Api(database_app, account())

    api.post("/api/v1/circles/self", {**SELF, "city": "لندن"})

    [home] = api.get("/api/v1/home").json["care_circles"]
    assert (home["latitude"], home["longitude"]) == (None, None)
