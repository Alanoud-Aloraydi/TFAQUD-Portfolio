"""The circle endpoints without a database.

These tests check what happens before any database work: who may call, and
whether the body is accepted. The work itself is tested against PostgreSQL in
integration_tests/.
"""

import pytest

from app.authz import CircleRole
from tests.conftest import bearer

CIRCLE = "11111111-1111-4111-8111-111111111111"
OTHER = "22222222-2222-4222-8222-222222222222"
PHONE = "+966512345678"

SELF_BODY = {
    "name": "My care",
    "birth_date": "1954-06-05",
    "city": "Riyadh",
}

ENDPOINTS = [
    ("get", "/api/v1/accounts/me"),
    ("delete", "/api/v1/accounts/me"),
    ("post", "/api/v1/circles/self"),
    ("post", "/api/v1/circles/patient-without-account"),
    ("get", f"/api/v1/circles/{CIRCLE}"),
    ("patch", f"/api/v1/circles/{CIRCLE}"),
    ("put", f"/api/v1/circles/{CIRCLE}/patient"),
    ("post", f"/api/v1/circles/{CIRCLE}/leave"),
    ("delete", f"/api/v1/circles/{CIRCLE}"),
    ("post", f"/api/v1/circles/{CIRCLE}/invitations"),
    ("post", f"/api/v1/circles/{CIRCLE}/invitations/{OTHER}/resend"),
    ("delete", f"/api/v1/circles/{CIRCLE}/invitations/{OTHER}"),
    ("get", f"/api/v1/circles/{CIRCLE}/medical-profile"),
    ("patch", f"/api/v1/circles/{CIRCLE}/medical-profile"),
    ("post", f"/api/v1/circles/{CIRCLE}/emergency-contacts"),
    ("put", f"/api/v1/circles/{CIRCLE}/emergency-contacts/{OTHER}"),
    ("delete", f"/api/v1/circles/{CIRCLE}/emergency-contacts/{OTHER}"),
    ("post", "/api/v1/circle-requests"),
    ("get", "/api/v1/circle-requests"),
    ("post", f"/api/v1/circle-requests/{OTHER}/respond"),
    ("post", f"/api/v1/circle-requests/{OTHER}/complete"),
    ("delete", f"/api/v1/circle-requests/{OTHER}"),
    ("get", "/api/v1/invitations"),
    ("post", f"/api/v1/invitations/{OTHER}/respond"),
]


def error_of(response, status, code):
    assert response.status_code == status, response.get_json()
    error = response.get_json()["error"]
    assert error["code"] == code
    return error


@pytest.mark.parametrize("method,url", ENDPOINTS)
def test_every_endpoint_needs_a_sign_in(client, method, url):
    response = getattr(client, method)(url, json={})

    error_of(response, 401, "missing_token")


@pytest.mark.parametrize(
    "method,url", [e for e in ENDPOINTS if CIRCLE in e[1]]
)
def test_a_circle_you_are_not_in_is_refused(client, signed_in, method, url):
    response = getattr(client, method)(
        url, json={}, headers=bearer(signed_in.access_token)
    )

    error_of(response, 403, "forbidden")


def test_a_simplified_patient_cannot_manage_the_circle(
    client, circle_access, signed_in, signed_in_account
):
    circle_access.grant(
        signed_in_account.id, CIRCLE, CircleRole.SIMPLIFIED_PATIENT
    )
    headers = bearer(signed_in.access_token)

    for method, url, body in [
        ("patch", f"/api/v1/circles/{CIRCLE}", {"name": "New"}),
        ("post", f"/api/v1/circles/{CIRCLE}/leave", {}),
        (
            "post",
            f"/api/v1/circles/{CIRCLE}/invitations",
            {"invitee_phone_number": PHONE},
        ),
    ]:
        response = getattr(client, method)(url, json=body, headers=headers)
        error_of(response, 403, "forbidden")


def test_the_account_page_reads_the_signed_in_account(
    client, signed_in, signed_in_account
):
    response = client.get(
        "/api/v1/accounts/me", headers=bearer(signed_in.access_token)
    )

    assert response.status_code == 200
    assert response.get_json()["account"]["phone_number"] == "+966501234567"
    assert response.get_json()["account"]["patient_circle_id"] is None
    assert response.headers["Cache-Control"] == "no-store"


@pytest.mark.parametrize(
    "change,field",
    [
        ({"name": None}, "name"),
        ({"name": ""}, "name"),
        ({"name": "x" * 61}, "name"),
        ({"birth_date": "05/06/1954"}, "birth_date"),
        ({"birth_date": 19540605}, "birth_date"),
        ({"birth_date": "1899-12-31"}, "birth_date"),
        ({"birth_date": "2026-13-40"}, "birth_date"),
        ({"city": ""}, "city"),
        ({"city": "Ri\nyadh"}, "city"),
        ({"latitude": 26.3}, "body"),
        ({"latitude": 91, "longitude": 43}, "latitude"),
        ({"latitude": 26, "longitude": 181}, "longitude"),
        ({"latitude": "26.3", "longitude": "43.9"}, "latitude"),
        ({"latitude": True, "longitude": 43}, "latitude"),
        ({"admin": True}, "admin"),
        (
            {"medical_profile": {"blood_type": "C+"}},
            "medical_profile.blood_type",
        ),
        (
            {
                "medical_profile": {
                    "conditions": {"status": "listed", "codes": ["flu"]}
                }
            },
            "medical_profile.conditions.codes.0",
        ),
        (
            {"medical_profile": {"allergies": {"status": "maybe"}}},
            "medical_profile.allergies.status",
        ),
    ],
)
def test_a_bad_body_is_refused_before_any_work(
    client, signed_in, change, field
):
    body = {**SELF_BODY, **change}
    body = {key: value for key, value in body.items() if value is not None}

    response = client.post(
        "/api/v1/circles/self",
        json=body,
        headers=bearer(signed_in.access_token),
    )

    error = error_of(response, 422, "validation_error")
    assert field in [item["field"] for item in error["details"]]


def test_a_valid_body_needs_the_database(client, signed_in):
    response = client.post(
        "/api/v1/circles/self",
        json=SELF_BODY,
        headers=bearer(signed_in.access_token),
    )

    error_of(response, 503, "service_unavailable")


def test_leaving_needs_no_body(
    client, circle_access, signed_in, signed_in_account
):
    circle_access.grant(signed_in_account.id, CIRCLE, CircleRole.MANAGER)

    response = client.post(
        f"/api/v1/circles/{CIRCLE}/leave",
        headers=bearer(signed_in.access_token),
    )

    # It reached the database step; a body was not required.
    error_of(response, 503, "service_unavailable")


def test_leaving_checks_a_body_when_one_is_sent(
    client, circle_access, signed_in, signed_in_account
):
    circle_access.grant(signed_in_account.id, CIRCLE, CircleRole.MANAGER)

    response = client.post(
        f"/api/v1/circles/{CIRCLE}/leave",
        json={"confirm_delete": "yes"},
        headers=bearer(signed_in.access_token),
    )

    error_of(response, 422, "validation_error")


@pytest.mark.parametrize(
    "body",
    [
        {
            "patient_phone_number": "0512345678",
            "circle_label": "Mother",
            "proposed_app_mode": "simplified",
        },
        {
            "patient_phone_number": PHONE,
            "circle_label": "",
            "proposed_app_mode": "simplified",
        },
        {
            "patient_phone_number": PHONE,
            "circle_label": "Mother",
            "proposed_app_mode": "full",
        },
    ],
)
def test_a_bad_creation_request_is_refused(client, signed_in, body):
    response = client.post(
        "/api/v1/circle-requests",
        json=body,
        headers=bearer(signed_in.access_token),
    )

    error_of(response, 422, "validation_error")


def test_responding_needs_a_real_yes_or_no(client, signed_in):
    response = client.post(
        f"/api/v1/circle-requests/{OTHER}/respond",
        json={"accept": "true"},
        headers=bearer(signed_in.access_token),
    )

    error_of(response, 422, "validation_error")


def test_an_emergency_contact_needs_a_saudi_mobile_number(
    client, circle_access, signed_in, signed_in_account
):
    circle_access.grant(signed_in_account.id, CIRCLE, CircleRole.MANAGER)

    response = client.post(
        f"/api/v1/circles/{CIRCLE}/emergency-contacts",
        json={"name": "Reem", "relation": "daughter", "phone_number": "123"},
        headers=bearer(signed_in.access_token),
    )

    error_of(response, 422, "validation_error")
