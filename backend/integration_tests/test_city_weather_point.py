"""The weather on «اليوم» follows the account's own city: its centre when
the city is in the app's list, none otherwise. A new city on the account
page also moves the zone of the circle the account is the patient of."""

from uuid import UUID

import pytest
from sqlalchemy.orm import Session

from app.database import db
from app.models import CareCircle
from integration_tests.helpers import Api

PROFILE = "/api/v1/accounts/me/profile"
NAMES = {"first_name": "Nora", "last_name": "Family", "display_name": "Nora"}


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release request transactions before the next test truncates tables."""
    yield
    db.session.remove()


def account_point(api):
    home = api.get("/api/v1/home").json["account"]
    return home["latitude"], home["longitude"]


def test_a_listed_city_gives_the_account_its_point(
    database_app, database, account
):
    api = Api(database_app, account())

    saved = api.put(PROFILE, {**NAMES, "city": "بريدة"})

    assert saved.status_code == 200, saved.get_json()
    assert account_point(api) == (26.3260, 43.9750)


def test_a_typed_city_leaves_it_without_one(database_app, database, account):
    api = Api(database_app, account())

    api.put(PROFILE, {**NAMES, "city": "لندن"})

    assert account_point(api) == (None, None)


def test_a_new_city_moves_the_zone_of_the_patients_circle(
    database_app, database, account
):
    api = Api(database_app, account())
    created = api.post(
        "/api/v1/circles/self",
        {"name": "My care", "birth_date": "1954-06-05", "city": "بريدة"},
    )
    assert created.status_code == 201, created.get_json()

    saved = api.put(
        PROFILE, {**NAMES, "city": "لندن", "time_zone": "Europe/London"}
    )

    assert saved.status_code == 200, saved.get_json()
    with Session(database) as session:
        circle = session.get(CareCircle, UUID(created.json["circle"]["id"]))
        assert circle.time_zone == "Europe/London"
    assert account_point(api) == (None, None)
