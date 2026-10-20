"""PUT /api/v1/users/me/profile: the page after the first sign-in."""

import pytest

from tests.conftest import bearer

PHONE = "+966501234567"
OTHER_PHONE = "+966512345678"

URL = "/api/v1/users/me/profile"
NAMES = {"first_name": "Leen", "last_name": "Algraawi", "display_name": "Leen"}

# "Leen" and "Algraawi" in Arabic, written as code points so the file stays ASCII.
ARABIC_FIRST = "".join(chr(code) for code in (0x0644, 0x064A, 0x0646))
ARABIC_LAST = "".join(chr(code) for code in (0x0627, 0x0644, 0x063A, 0x0631, 0x0627, 0x0648, 0x064A))


def sign_in(client, sms, phone=PHONE):
    """Sign a phone number in through the real endpoints. Returns the response body."""
    vid = client.post("/api/v1/auth/request-code", json={"phone": phone}).get_json()[
        "verification_id"
    ]
    code = sms.last_message_to(phone).code
    response = client.post(
        "/api/v1/auth/verify-code", json={"verification_id": vid, "code": code}
    )
    assert response.status_code == 200
    return response.get_json()


def save(client, token, body):
    return client.put(URL, json=body, headers=bearer(token))


def error_of(response, status, code):
    assert response.status_code == status, response.get_json()
    error = response.get_json()["error"]
    assert error["code"] == code
    return error


def test_the_profile_needs_a_signed_in_user(client):
    response = client.put(URL, json=NAMES)

    error_of(response, 401, "missing_token")


def test_saving_the_profile_returns_the_user_with_a_complete_profile(client, sms):
    session = sign_in(client, sms)

    response = save(client, session["access_token"], NAMES)

    assert response.status_code == 200
    user = response.get_json()["user"]
    assert user["id"] == session["user"]["id"]
    assert user["phone"] == PHONE
    assert (user["first_name"], user["last_name"], user["display_name"]) == (
        "Leen",
        "Algraawi",
        "Leen",
    )
    assert user["profile_complete"] is True


def test_the_profile_is_kept_in_the_user_store(client, sms, user_store):
    session = sign_in(client, sms)

    save(client, session["access_token"], NAMES)

    stored = user_store.get(session["user"]["id"])
    assert stored.first_name == "Leen"
    assert stored.profile_complete is True


def test_arabic_names_are_accepted(client, sms):
    session = sign_in(client, sms)
    body = {
        "first_name": ARABIC_FIRST,
        "last_name": ARABIC_LAST,
        "display_name": ARABIC_FIRST,
    }

    response = save(client, session["access_token"], body)

    assert response.status_code == 200
    assert response.get_json()["user"]["first_name"] == ARABIC_FIRST


def test_spaces_around_the_names_are_removed(client, sms):
    session = sign_in(client, sms)
    body = {"first_name": "  Leen ", "last_name": " Algraawi  ", "display_name": " Leen "}

    user = save(client, session["access_token"], body).get_json()["user"]

    assert (user["first_name"], user["last_name"], user["display_name"]) == (
        "Leen",
        "Algraawi",
        "Leen",
    )


def test_saving_again_replaces_the_names(client, sms):
    session = sign_in(client, sms)
    save(client, session["access_token"], NAMES)

    changed = {"first_name": "Sara", "last_name": "Ali", "display_name": "Sarah"}
    user = save(client, session["access_token"], changed).get_json()["user"]

    assert user["first_name"] == "Sara"
    assert user["display_name"] == "Sarah"


def test_each_user_has_their_own_profile(client, sms):
    first = sign_in(client, sms, PHONE)
    second = sign_in(client, sms, OTHER_PHONE)

    save(client, first["access_token"], NAMES)
    save(
        client,
        second["access_token"],
        {"first_name": "Sara", "last_name": "Ali", "display_name": "Sarah"},
    )

    # Signing in again returns what each user saved, and only that.
    assert sign_in(client, sms, PHONE)["user"]["first_name"] == "Leen"
    assert sign_in(client, sms, OTHER_PHONE)["user"]["first_name"] == "Sara"


def test_the_names_cannot_choose_a_different_user(client, sms):
    first = sign_in(client, sms, PHONE)
    second = sign_in(client, sms, OTHER_PHONE)

    response = save(
        client, first["access_token"], {**NAMES, "user_id": second["user"]["id"]}
    )

    error_of(response, 422, "validation_error")
    assert sign_in(client, sms, OTHER_PHONE)["user"]["first_name"] is None


@pytest.mark.parametrize("field", ["first_name", "last_name", "display_name"])
def test_every_name_is_required(client, sms, field):
    session = sign_in(client, sms)
    body = {k: v for k, v in NAMES.items() if k != field}

    error = error_of(save(client, session["access_token"], body), 422, "validation_error")

    assert error["details"][0]["field"] == field


@pytest.mark.parametrize("field", ["first_name", "last_name", "display_name"])
@pytest.mark.parametrize("value", ["", "   "])
def test_a_name_cannot_be_empty_or_only_spaces(client, sms, field, value):
    session = sign_in(client, sms)

    response = save(client, session["access_token"], {**NAMES, field: value})

    error = error_of(response, 422, "validation_error")
    assert error["details"][0]["field"] == field


@pytest.mark.parametrize(
    ("field", "limit"), [("first_name", 50), ("last_name", 50), ("display_name", 30)]
)
def test_names_have_a_maximum_length(client, sms, field, limit):
    session = sign_in(client, sms)

    ok = save(client, session["access_token"], {**NAMES, field: "a" * limit})
    too_long = save(client, session["access_token"], {**NAMES, field: "a" * (limit + 1)})

    assert ok.status_code == 200
    error = error_of(too_long, 422, "validation_error")
    assert error["details"][0]["field"] == field


@pytest.mark.parametrize("value", ["Leen\nAlgraawi", "Leen\tA", "Le\x00en"])
def test_a_name_is_one_line_without_control_characters(client, sms, value):
    session = sign_in(client, sms)

    response = save(client, session["access_token"], {**NAMES, "first_name": value})

    error = error_of(response, 422, "validation_error")
    assert error["details"][0]["code"] == "invalid_name"


def test_unknown_fields_are_refused(client, sms):
    session = sign_in(client, sms)

    response = save(client, session["access_token"], {**NAMES, "age": 20})

    error_of(response, 422, "validation_error")


def test_a_signed_out_session_cannot_save_the_profile(client, sms):
    session = sign_in(client, sms)
    token = session["access_token"]
    assert client.post("/api/v1/auth/sign-out", headers=bearer(token)).status_code == 204

    response = save(client, token, NAMES)

    error_of(response, 401, "session_revoked")


def test_a_token_of_a_user_that_does_not_exist_gets_a_clear_answer(client, sessions):
    ghost = sessions.create_session("a-user-that-was-never-created")

    response = save(client, ghost.access_token, NAMES)

    error_of(response, 404, "user_not_found")
