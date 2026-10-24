"""Authentication through Flask with real PostgreSQL and fake SMS only."""

from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from uuid import UUID

import pytest
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app import create_app
from app.auth.postgres_otp import PostgresOtpStore
from app.clock import ManualClock
from app.models import Account, AccountSession, OtpChallenge, OtpSendAttempt
from app.sms.base import SmsDeliveryError

PHONE = "+966501234567"


@pytest.fixture
def auth_app(database, database_app):
    """Each app uses durable stores but sends no network messages."""
    app = create_app(
        "testing",
        clock=ManualClock(),
        overrides={
            "SQLALCHEMY_DATABASE_URI": database_app.config[
                "SQLALCHEMY_DATABASE_URI"
            ],
            "SQLALCHEMY_ENGINE_OPTIONS": database_app.config[
                "SQLALCHEMY_ENGINE_OPTIONS"
            ],
        },
    )
    yield app
    from app.database import db

    with app.app_context():
        db.session.remove()
        db.engine.dispose()


def restarted(app):
    """Recreate application services against the same external stores."""
    return create_app(
        "testing",
        clock=app.extensions["clock"],
        sms_sender=app.extensions["sms_sender"],
        overrides={
            "SQLALCHEMY_DATABASE_URI": app.config["SQLALCHEMY_DATABASE_URI"]
        },
    )


def start(client, verification_id=None):
    """Request or resend an OTP without exposing the fake code in output."""
    body = {"phone_number": PHONE}
    if verification_id:
        body["verification_id"] = verification_id
    response = client.post("/api/v1/auth/request-code", json=body)
    assert response.status_code == 200
    return response.json["verification_id"]


def verify(app, verification_id):
    code = app.extensions["sms_sender"].last_message_to(PHONE).code
    return app.test_client().post(
        "/api/v1/auth/verify-code",
        json={"verification_id": verification_id, "code": code},
    )


def headers(body):
    return {"Authorization": "Bearer " + body["access_token"]}


def test_signup_profile_and_returning_account_are_persisted(
    auth_app, database
):
    client = auth_app.test_client()
    first = verify(auth_app, start(client))
    assert first.status_code == 200
    assert first.json["account"]["profile_complete"] is False
    saved = client.put(
        "/api/v1/accounts/me/profile",
        headers=headers(first.json),
        json={
            "first_name": "Nora",
            "last_name": "Family",
            "display_name": "Nora",
        },
    )
    assert saved.status_code == 200
    second_app = restarted(auth_app)
    second = verify(second_app, start(second_app.test_client()))
    assert second.status_code == 200
    assert second.json["account"]["id"] == first.json["account"]["id"]
    assert second.json["account"]["profile_complete"] is True
    with Session(database) as session:
        assert session.scalar(select(func.count()).select_from(Account)) == 1
        assert (
            session.scalar(select(func.count()).select_from(AccountSession))
            == 2
        )
        row = session.scalar(select(AccountSession).limit(1))
        assert row.refresh_token_hash not in {
            first.json["refresh_token"],
            second.json["refresh_token"],
        }


def test_session_and_logout_survive_app_restart(auth_app):
    body = verify(auth_app, start(auth_app.test_client())).json
    client = restarted(auth_app).test_client()
    restored = client.get("/api/v1/auth/session", headers=headers(body))
    assert restored.status_code == 200
    assert restored.json["account"]["profile_complete"] is False
    assert (
        client.post("/api/v1/auth/sign-out", headers=headers(body)).status_code
        == 204
    )
    after = restarted(auth_app).test_client()
    assert (
        after.get("/api/v1/auth/session", headers=headers(body)).status_code
        == 401
    )
    assert (
        after.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": body["refresh_token"]},
        ).status_code
        == 401
    )


def test_logout_preserves_another_session(auth_app):
    client = auth_app.test_client()
    first = verify(auth_app, start(client)).json
    second = verify(auth_app, start(client)).json
    client.post("/api/v1/auth/sign-out", headers=headers(first))
    after = restarted(auth_app).test_client()
    assert (
        after.get("/api/v1/auth/session", headers=headers(second)).status_code
        == 200
    )
    assert (
        after.get("/api/v1/auth/session", headers=headers(first)).status_code
        == 401
    )


def test_pending_challenge_and_quotas_survive_restart(auth_app, database):
    client = auth_app.test_client()
    challenge = start(client)
    code = auth_app.extensions["sms_sender"].last_message_to(PHONE).code
    wrong = "000000" if code != "000000" else "111111"
    response = client.post(
        "/api/v1/auth/verify-code",
        json={"verification_id": challenge, "code": wrong},
    )
    assert response.json["error"]["code"] == "invalid_code"
    after = restarted(auth_app)
    with after.app_context():
        request = after.extensions["sign_in_service"]._otp.get_request(
            challenge
        )
        assert request.wrong_tries == 1
    start(after.test_client(), challenge)
    start(after.test_client(), challenge)
    assert (
        after.test_client()
        .post("/api/v1/auth/request-code", json={"phone_number": PHONE})
        .status_code
        == 429
    )
    assert verify(after, challenge).status_code == 200
    with Session(database) as session:
        row = session.get(OtpChallenge, UUID(challenge))
        assert row.status == "verified"
        assert row.expires_at is not None


def test_new_challenge_supersedes_previous_request(auth_app):
    client = auth_app.test_client()
    previous = start(client)
    current = start(client)
    response = verify(auth_app, previous)
    assert response.status_code == 404
    assert verify(auth_app, current).status_code == 200


def test_concurrent_quota_claims_cannot_exceed_three(auth_app, database):
    now = auth_app.extensions["clock"].now()

    def claim(_):
        with auth_app.app_context():
            return (
                PostgresOtpStore()
                .claim_send(None, PHONE, now, now - timedelta(hours=1), 3)
                .granted
            )

    with ThreadPoolExecutor(max_workers=8) as executor:
        results = list(executor.map(claim, range(20)))
    assert results.count(True) == 3
    with Session(database) as session:
        assert (
            session.scalar(select(func.count()).select_from(OtpSendAttempt))
            == 3
        )
        assert (
            session.scalar(
                select(func.count())
                .select_from(OtpChallenge)
                .where(OtpChallenge.status == "pending")
            )
            == 1
        )


def test_resend_rechecks_attempts_before_reserving_delivery(
    auth_app, database, monkeypatch
):
    """Attempts consumed just before reservation cannot trigger another SMS."""
    challenge = start(auth_app.test_client())
    store = auth_app.extensions["sign_in_service"]._otp
    reserve = store.claim_send

    def exhausted_before_claim(*args, **kwargs):
        for _ in range(3):
            assert store.claim_try(challenge, 3)
        return reserve(*args, **kwargs)

    monkeypatch.setattr(store, "claim_send", exhausted_before_claim)
    response = auth_app.test_client().post(
        "/api/v1/auth/request-code",
        json={"phone_number": PHONE, "verification_id": challenge},
    )
    assert response.status_code == 429
    assert response.json["error"]["code"] == "too_many_attempts"
    with Session(database) as session:
        assert (
            session.scalar(select(func.count()).select_from(OtpSendAttempt))
            == 1
        )


def test_concurrent_verification_attempts_cannot_exceed_three(auth_app):
    challenge = start(auth_app.test_client())

    def attempt(_):
        with auth_app.app_context():
            return PostgresOtpStore().claim_try(challenge, 3)

    with ThreadPoolExecutor(max_workers=8) as executor:
        results = list(executor.map(attempt, range(20)))
    assert results.count(True) == 3
    assert verify(auth_app, challenge).status_code == 429


def test_concurrent_success_creates_one_session(
    auth_app, database, monkeypatch
):
    challenge = start(auth_app.test_client())
    monkeypatch.setattr(
        auth_app.extensions["sms_sender"], "check_code", lambda *_: True
    )

    def finish(_):
        return verify(auth_app, challenge).status_code

    with ThreadPoolExecutor(max_workers=2) as executor:
        results = list(executor.map(finish, range(2)))
    assert sorted(results) == [200, 422]
    with Session(database) as session:
        assert (
            session.scalar(select(func.count()).select_from(AccountSession))
            == 1
        )


def test_refresh_expiry_ends_access_even_before_jwt_expiry(auth_app):
    body = verify(auth_app, start(auth_app.test_client())).json
    auth_app.extensions["clock"].advance(days=29, hours=23, minutes=59)
    client = auth_app.test_client()
    refreshed = client.post(
        "/api/v1/auth/refresh", json={"refresh_token": body["refresh_token"]}
    )
    assert refreshed.status_code == 200
    auth_app.extensions["clock"].advance(minutes=1)
    result = client.get(
        "/api/v1/auth/session", headers=headers(refreshed.json)
    )
    assert result.status_code == 401


def test_account_deletion_removes_sessions(auth_app, database):
    body = verify(auth_app, start(auth_app.test_client())).json
    with Session(database) as session, session.begin():
        row = session.get(Account, UUID(body["account"]["id"]))
        session.delete(row)
    assert (
        restarted(auth_app)
        .test_client()
        .get("/api/v1/auth/session", headers=headers(body))
        .status_code
        == 401
    )


def test_failed_session_insert_rolls_back_account_and_verification(
    auth_app, database, monkeypatch
):
    challenge = start(auth_app.test_client())
    store = auth_app.extensions["session_service"]._store
    real_add = store.add

    def fail_after_insert(record):
        real_add(record)
        raise RuntimeError("Simulated persistence failure")

    monkeypatch.setattr(store, "add", fail_after_insert)
    assert verify(auth_app, challenge).status_code == 500
    with Session(database) as session:
        assert session.scalar(select(func.count()).select_from(Account)) == 0
        assert (
            session.scalar(select(func.count()).select_from(AccountSession))
            == 0
        )
        row = session.get(OtpChallenge, UUID(challenge))
        assert row.status == "pending" and row.verified_at is None


@pytest.mark.parametrize(
    "status, expected", [(422, "failed"), (None, "reserved")]
)
def test_delivery_uncertainty_retains_quota(
    auth_app, database, monkeypatch, status, expected
):
    def rejected(phone):
        raise SmsDeliveryError("Simulated provider failure", status=status)

    monkeypatch.setattr(
        auth_app.extensions["sms_sender"], "send_code", rejected
    )
    client = auth_app.test_client()
    for _ in range(3):
        assert (
            client.post(
                "/api/v1/auth/request-code", json={"phone_number": PHONE}
            ).status_code
            == 503
        )
    result = client.post(
        "/api/v1/auth/request-code", json={"phone_number": PHONE}
    )
    assert result.status_code == (503 if status == 422 else 429)
    with Session(database) as session:
        assert set(session.scalars(select(OtpSendAttempt.status))) == {
            expected
        }
