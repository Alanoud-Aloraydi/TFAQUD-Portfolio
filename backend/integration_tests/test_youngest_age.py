"""Whoever has an account is 15 or older; a patient cared for without an
account (a child) may be any age. On PostgreSQL through the real
endpoints; the account's own profile is in tests/test_profile.py."""

from integration_tests.helpers import Api, error_code
from integration_tests.test_circle_api import OFFLINE

# On the integration clock's day, 14 years old: too young for an account.
CHILD = "2012-01-02"


def test_a_child_without_an_account_can_be_cared_for(database_app, account):
    api = Api(database_app, account())

    response = api.post(
        "/api/v1/circles/patient-without-account",
        {**OFFLINE, "birth_date": CHILD},
    )

    assert response.status_code == 201, response.json


def test_an_own_circle_needs_15_years(database_app, account):
    api = Api(database_app, account())

    response = api.post(
        "/api/v1/circles/self",
        {"name": "Mine", "birth_date": CHILD, "city": "Riyadh"},
    )

    assert error_code(response, 422) == "too_young"
