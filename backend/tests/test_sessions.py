"""Sessions: access token, refresh token, sign-out.

The rules of TFQD-6 / TFQD-11 are tested here:
  1. an expired access token is rejected, and a refresh gives a new one;
  2. after sign-out the refresh token is rejected (acceptance criterion);
  3. after sign-out the old access token is rejected too;
  4. a refresh token has no end date: only a sign-out ends it.
"""

import jwt

from tests.conftest import bearer

SESSION = "/api/v1/auth/session"
REFRESH = "/api/v1/auth/refresh"
SIGN_OUT = "/api/v1/auth/sign-out"


def error_code(response):
    return response.get_json()["error"]["code"]


def session_of(client, access_token):
    """The protected session endpoint, called with [access_token]."""
    return client.get(SESSION, headers=bearer(access_token))


def refresh_with(client, refresh_token):
    return client.post(REFRESH, json={"refresh_token": refresh_token})


def sign_out_with(client, access_token):
    return client.post(SIGN_OUT, headers=bearer(access_token))


# ---------------------------------------------------------------- access token


def test_valid_access_token_reaches_a_protected_endpoint(client, signed_in):
    response = session_of(client, signed_in.access_token)

    assert response.status_code == 200
    body = response.get_json()
    assert body["session_id"] == signed_in.session_id
    assert body["account_id"] == body["account"]["id"]
    assert body["account"]["profile_complete"] is False
    assert body["account"]["app_mode"] is None


def test_missing_header_is_rejected(client):
    response = client.get(SESSION)

    assert response.status_code == 401
    assert error_code(response) == "missing_token"


def test_wrong_scheme_is_rejected(client, signed_in):
    response = client.get(
        SESSION,
        headers={"Authorization": f"Basic {signed_in.access_token}"},
    )

    assert response.status_code == 401
    assert error_code(response) == "missing_token"


def test_garbage_token_is_rejected(client):
    response = session_of(client, "not-a-token")

    assert response.status_code == 401
    assert error_code(response) == "invalid_token"


def test_token_signed_with_another_key_is_rejected(client, signed_in, clock):
    forged = jwt.encode(
        {
            "typ": "access",
            "sub": "user-1",
            "sid": signed_in.session_id,
            "exp": int(clock.now().timestamp()) + 900,
        },
        "a-different-secret-key-of-enough-length-1234",
        algorithm="HS256",
    )

    response = session_of(client, forged)

    assert response.status_code == 401
    assert error_code(response) == "invalid_token"


def test_token_with_algorithm_none_is_rejected(client, signed_in, clock):
    unsigned = jwt.encode(
        {
            "typ": "access",
            "sub": "user-1",
            "sid": signed_in.session_id,
            "exp": int(clock.now().timestamp()) + 900,
        },
        key=None,
        algorithm="none",
    )

    response = session_of(client, unsigned)

    assert response.status_code == 401
    assert error_code(response) == "invalid_token"


def test_tampered_token_is_rejected(client, signed_in):
    header, payload, signature = signed_in.access_token.split(".")
    changed_end = "AA" if payload[-2:] != "AA" else "BB"
    tampered = ".".join([header, payload[:-2] + changed_end, signature])

    response = session_of(client, tampered)

    assert response.status_code == 401
    assert error_code(response) == "invalid_token"


def test_refresh_token_cannot_be_used_as_an_access_token(client, signed_in):
    response = session_of(client, signed_in.refresh_token)

    assert response.status_code == 401
    assert error_code(response) == "invalid_token"


def test_access_token_lives_15_minutes(client, signed_in, clock):
    clock.advance(minutes=14, seconds=59)
    still_valid = session_of(client, signed_in.access_token)
    clock.advance(seconds=1)
    expired = session_of(client, signed_in.access_token)

    assert still_valid.status_code == 200
    assert expired.status_code == 401
    assert error_code(expired) == "access_token_expired"


# --------------------------------------------------------------------- refresh


def test_expired_access_token_can_be_replaced_with_a_refresh(
    client, signed_in, clock
):
    clock.advance(minutes=20)
    assert session_of(client, signed_in.access_token).status_code == 401

    refreshed = refresh_with(client, signed_in.refresh_token)

    assert refreshed.status_code == 200
    new_access = refreshed.get_json()["access_token"]
    assert new_access != signed_in.access_token
    retry = session_of(client, new_access)
    assert retry.status_code == 200
    # The same session.
    assert retry.get_json()["session_id"] == signed_in.session_id


def test_refresh_response_has_the_new_expiry_time(client, signed_in, clock):
    clock.advance(minutes=20)

    body = refresh_with(client, signed_in.refresh_token).get_json()

    assert body["access_token_expires_at"] == "2026-10-15T12:35:00+00:00"


def test_unknown_refresh_token_is_rejected(client):
    response = refresh_with(client, "made-up")

    assert response.status_code == 401
    assert error_code(response) == "invalid_refresh_token"


def test_a_refresh_token_never_ends_by_itself(client, signed_in, clock):
    # Well past the 30 days it used to have, and years later.
    for days in (31, 365 * 3):
        clock.advance(days=days)
        refreshed = refresh_with(client, signed_in.refresh_token)
        assert refreshed.status_code == 200
        # And the access token it gives works.
        access = refreshed.get_json()["access_token"]
        assert session_of(client, access).status_code == 200


def test_after_years_a_sign_out_still_ends_the_session(
    client, signed_in, clock
):
    clock.advance(days=365 * 2)
    access = refresh_with(
        client, signed_in.refresh_token
    ).get_json()["access_token"]

    sign_out_with(client, access)

    after = refresh_with(client, signed_in.refresh_token)
    assert after.status_code == 401
    assert error_code(after) == "invalid_refresh_token"


# -------------------------------------------------------------------- sign-out


def test_sign_out_returns_204(client, signed_in):
    response = sign_out_with(client, signed_in.access_token)

    assert response.status_code == 204
    assert response.get_data() == b""


def test_sign_out_needs_a_valid_access_token(client):
    response = client.post(SIGN_OUT)

    assert response.status_code == 401


def test_refresh_token_of_a_revoked_session_is_rejected(client, signed_in):
    """Acceptance criterion of TFQD-6."""
    before = refresh_with(client, signed_in.refresh_token)
    assert before.status_code == 200

    sign_out_with(client, signed_in.access_token)

    after = refresh_with(client, signed_in.refresh_token)
    assert after.status_code == 401
    assert error_code(after) == "invalid_refresh_token"


def test_access_token_of_a_revoked_session_is_rejected_at_once(
    client, signed_in
):
    """The access token is still inside its 15 minutes, but the session
    has ended."""
    sign_out_with(client, signed_in.access_token)

    response = session_of(client, signed_in.access_token)

    assert response.status_code == 401
    assert error_code(response) == "session_revoked"


def test_access_token_issued_by_a_refresh_dies_with_the_session(
    client, signed_in, clock
):
    clock.advance(minutes=20)
    new_access = refresh_with(
        client, signed_in.refresh_token
    ).get_json()["access_token"]

    sign_out_with(client, new_access)

    response = session_of(client, new_access)
    assert error_code(response) == "session_revoked"


def test_signing_out_twice_does_not_break_anything(
    client, signed_in, sessions
):
    sign_out_with(client, signed_in.access_token)

    sessions.sign_out(signed_in.session_id)  # a second sign-out, no error

    response = refresh_with(client, signed_in.refresh_token)
    assert response.status_code == 401


def test_sign_out_ends_only_that_session(client, sessions, user_store, clock):
    user, _ = user_store.get_or_create_by_phone("+966501234567", clock.now())
    phone = sessions.create_session(user.id)
    tablet = sessions.create_session(user.id)

    sign_out_with(client, phone.access_token)

    assert refresh_with(client, phone.refresh_token).status_code == 401
    assert refresh_with(client, tablet.refresh_token).status_code == 200
    assert session_of(client, tablet.access_token).status_code == 200


# --------------------------------------------------------------------- storage


def test_the_store_keeps_only_a_hash_of_the_refresh_token(app, signed_in):
    store = app.extensions["session_service"]._store
    record = store.get(signed_in.session_id)

    assert record.refresh_token_hash != signed_in.refresh_token
    assert signed_in.refresh_token not in repr(record)
    assert len(record.refresh_token_hash) == 64  # SHA-256 in hexadecimal


def test_no_device_or_ip_is_stored_with_a_session(app, signed_in):
    record = app.extensions["session_service"]._store.get(signed_in.session_id)

    assert set(vars(record)) == {
        "id",
        "user_id",
        "refresh_token_hash",
        "created_at",
        "revoked_at",
    }
