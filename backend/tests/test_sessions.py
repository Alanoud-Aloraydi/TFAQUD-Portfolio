"""Sessions: access token, refresh token, sign-out.

The three rules of TFQD-6 / TFQD-11 are tested here:
  1. an expired access token is rejected, and a refresh gives a new one;
  2. after sign-out the refresh token is rejected (acceptance criterion);
  3. after sign-out the old access token is rejected too.
"""

import jwt

from tests.conftest import bearer


def error_code(response):
    return response.get_json()["error"]["code"]


# ---------------------------------------------------------------- access token


def test_valid_access_token_reaches_a_protected_endpoint(client, signed_in):
    response = client.get("/api/v1/auth/session", headers=bearer(signed_in.access_token))

    assert response.status_code == 200
    body = response.get_json()
    assert body["session_id"] == signed_in.session_id
    assert body["account_id"] == body["account"]["id"]
    assert body["account"]["profile_complete"] is False
    assert body["account"]["app_mode"] is None


def test_missing_header_is_rejected(client):
    response = client.get("/api/v1/auth/session")

    assert response.status_code == 401
    assert error_code(response) == "missing_token"


def test_wrong_scheme_is_rejected(client, signed_in):
    response = client.get(
        "/api/v1/auth/session", headers={"Authorization": f"Basic {signed_in.access_token}"}
    )

    assert response.status_code == 401
    assert error_code(response) == "missing_token"


def test_garbage_token_is_rejected(client):
    response = client.get("/api/v1/auth/session", headers=bearer("not-a-token"))

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

    response = client.get("/api/v1/auth/session", headers=bearer(forged))

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

    response = client.get("/api/v1/auth/session", headers=bearer(unsigned))

    assert response.status_code == 401
    assert error_code(response) == "invalid_token"


def test_tampered_token_is_rejected(client, signed_in):
    header, payload, signature = signed_in.access_token.split(".")
    tampered = ".".join([header, payload[:-2] + ("AA" if payload[-2:] != "AA" else "BB"), signature])

    response = client.get("/api/v1/auth/session", headers=bearer(tampered))

    assert response.status_code == 401
    assert error_code(response) == "invalid_token"


def test_refresh_token_cannot_be_used_as_an_access_token(client, signed_in):
    response = client.get("/api/v1/auth/session", headers=bearer(signed_in.refresh_token))

    assert response.status_code == 401
    assert error_code(response) == "invalid_token"


def test_access_token_lives_15_minutes(client, signed_in, clock):
    clock.advance(minutes=14, seconds=59)
    still_valid = client.get("/api/v1/auth/session", headers=bearer(signed_in.access_token))
    clock.advance(seconds=1)
    expired = client.get("/api/v1/auth/session", headers=bearer(signed_in.access_token))

    assert still_valid.status_code == 200
    assert expired.status_code == 401
    assert error_code(expired) == "access_token_expired"


# --------------------------------------------------------------------- refresh


def test_expired_access_token_can_be_replaced_with_a_refresh(client, signed_in, clock):
    clock.advance(minutes=20)
    assert (
        client.get("/api/v1/auth/session", headers=bearer(signed_in.access_token)).status_code
        == 401
    )

    refreshed = client.post("/api/v1/auth/refresh", json={"refresh_token": signed_in.refresh_token})

    assert refreshed.status_code == 200
    new_access = refreshed.get_json()["access_token"]
    assert new_access != signed_in.access_token
    retry = client.get("/api/v1/auth/session", headers=bearer(new_access))
    assert retry.status_code == 200
    assert retry.get_json()["session_id"] == signed_in.session_id  # same session


def test_refresh_response_has_the_new_expiry_time(client, signed_in, clock):
    clock.advance(minutes=20)

    body = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": signed_in.refresh_token}
    ).get_json()

    assert body["access_token_expires_at"] == "2026-10-15T12:35:00+00:00"


def test_unknown_refresh_token_is_rejected(client):
    response = client.post("/api/v1/auth/refresh", json={"refresh_token": "made-up"})

    assert response.status_code == 401
    assert error_code(response) == "invalid_refresh_token"


def test_refresh_token_lives_30_days(client, signed_in, clock):
    clock.advance(days=29, hours=23)
    still_valid = client.post("/api/v1/auth/refresh", json={"refresh_token": signed_in.refresh_token})
    clock.advance(hours=1)
    expired = client.post("/api/v1/auth/refresh", json={"refresh_token": signed_in.refresh_token})

    assert still_valid.status_code == 200
    assert expired.status_code == 401
    assert error_code(expired) == "invalid_refresh_token"


# -------------------------------------------------------------------- sign-out


def test_sign_out_returns_204(client, signed_in):
    response = client.post("/api/v1/auth/sign-out", headers=bearer(signed_in.access_token))

    assert response.status_code == 204
    assert response.get_data() == b""


def test_sign_out_needs_a_valid_access_token(client):
    response = client.post("/api/v1/auth/sign-out")

    assert response.status_code == 401


def test_refresh_token_of_a_revoked_session_is_rejected(client, signed_in):
    """Acceptance criterion of TFQD-6."""
    before = client.post("/api/v1/auth/refresh", json={"refresh_token": signed_in.refresh_token})
    assert before.status_code == 200

    client.post("/api/v1/auth/sign-out", headers=bearer(signed_in.access_token))

    after = client.post("/api/v1/auth/refresh", json={"refresh_token": signed_in.refresh_token})
    assert after.status_code == 401
    assert error_code(after) == "invalid_refresh_token"


def test_access_token_of_a_revoked_session_is_rejected_at_once(client, signed_in):
    """The access token is still inside its 15 minutes, but the session has ended."""
    client.post("/api/v1/auth/sign-out", headers=bearer(signed_in.access_token))

    response = client.get("/api/v1/auth/session", headers=bearer(signed_in.access_token))

    assert response.status_code == 401
    assert error_code(response) == "session_revoked"


def test_access_token_issued_by_a_refresh_dies_with_the_session(client, signed_in, clock):
    clock.advance(minutes=20)
    new_access = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": signed_in.refresh_token}
    ).get_json()["access_token"]

    client.post("/api/v1/auth/sign-out", headers=bearer(new_access))

    response = client.get("/api/v1/auth/session", headers=bearer(new_access))
    assert error_code(response) == "session_revoked"


def test_signing_out_twice_does_not_break_anything(client, signed_in, sessions):
    client.post("/api/v1/auth/sign-out", headers=bearer(signed_in.access_token))

    sessions.sign_out(signed_in.session_id)  # a second sign-out, no error

    response = client.post("/api/v1/auth/refresh", json={"refresh_token": signed_in.refresh_token})
    assert response.status_code == 401


def test_sign_out_ends_only_that_session(client, sessions, user_store, clock):
    user, _ = user_store.get_or_create_by_phone("+966501234567", clock.now())
    phone = sessions.create_session(user.id)
    tablet = sessions.create_session(user.id)

    client.post("/api/v1/auth/sign-out", headers=bearer(phone.access_token))

    assert (
        client.post("/api/v1/auth/refresh", json={"refresh_token": phone.refresh_token}).status_code
        == 401
    )
    assert (
        client.post("/api/v1/auth/refresh", json={"refresh_token": tablet.refresh_token}).status_code
        == 200
    )
    assert (
        client.get("/api/v1/auth/session", headers=bearer(tablet.access_token)).status_code == 200
    )


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
        "refresh_expires_at",
        "revoked_at",
    }
