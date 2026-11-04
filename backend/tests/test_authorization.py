"""The circle authorization interface.

The test app gets a small route that needs a role in the circle named in the
URL. Real circle routes will use the same decorator.
"""

from types import SimpleNamespace
from unittest.mock import Mock
from uuid import uuid4

import pytest

from app import photo_routes
from app.authz import CircleRole, current_circle_role, require_circle_role
from app.errors import NotFound
from tests.conftest import bearer


@pytest.fixture
def circle_app(app):
    @app.get("/test/circles/<circle_id>/today")
    @require_circle_role(CircleRole.MANAGER, CircleRole.PATIENT)
    def today(circle_id):
        return {"circle_id": circle_id, "role": current_circle_role().value}

    @app.get("/test/circles/<circle_id>/anyone")
    @require_circle_role()
    def anyone(circle_id):
        return {"role": current_circle_role().value}

    return app


@pytest.fixture
def circle_client(circle_app):
    return circle_app.test_client()


def test_member_with_an_allowed_role_gets_in(
    circle_client, circle_access, signed_in, signed_in_account
):
    circle_access.grant(signed_in_account.id, "circle-A", CircleRole.MANAGER)

    response = circle_client.get(
        "/test/circles/circle-A/today", headers=bearer(signed_in.access_token)
    )

    assert response.status_code == 200
    assert response.get_json() == {"circle_id": "circle-A", "role": "manager"}


def test_member_with_a_role_that_is_not_allowed_is_refused(
    circle_client, circle_access, signed_in, signed_in_account
):
    circle_access.grant(
        signed_in_account.id, "circle-A", CircleRole.SIMPLIFIED_PATIENT
    )

    response = circle_client.get(
        "/test/circles/circle-A/today", headers=bearer(signed_in.access_token)
    )

    assert response.status_code == 403
    assert response.get_json()["error"]["code"] == "forbidden"


def test_role_in_one_circle_gives_nothing_in_another(
    circle_client, circle_access, signed_in, signed_in_account
):
    circle_access.grant(signed_in_account.id, "circle-A", CircleRole.MANAGER)

    response = circle_client.get(
        "/test/circles/circle-B/today", headers=bearer(signed_in.access_token)
    )

    assert response.status_code == 403


def test_a_different_role_in_each_circle_is_respected(
    circle_client, circle_access, signed_in, signed_in_account
):
    circle_access.grant(signed_in_account.id, "circle-A", CircleRole.MANAGER)
    circle_access.grant(
        signed_in_account.id, "circle-B", CircleRole.SIMPLIFIED_PATIENT
    )
    headers = bearer(signed_in.access_token)

    assert circle_client.get("/test/circles/circle-A/today", headers=headers).status_code == 200
    assert circle_client.get("/test/circles/circle-B/today", headers=headers).status_code == 403
    assert circle_client.get("/test/circles/circle-B/anyone", headers=headers).status_code == 200


def test_non_member_and_unknown_circle_get_the_same_answer(
    circle_client, circle_access, signed_in
):
    circle_access.grant("someone-else", "circle-A", CircleRole.MANAGER)
    headers = bearer(signed_in.access_token)

    real_but_not_member = circle_client.get("/test/circles/circle-A/today", headers=headers)
    does_not_exist = circle_client.get("/test/circles/no-such-circle/today", headers=headers)

    assert real_but_not_member.status_code == does_not_exist.status_code == 403
    assert real_but_not_member.get_json()["error"]["code"] == does_not_exist.get_json()["error"]["code"]
    assert real_but_not_member.get_json()["error"]["message"] == does_not_exist.get_json()["error"]["message"]


def test_no_roles_listed_accepts_any_member(
    circle_client, circle_access, signed_in, signed_in_account
):
    circle_access.grant(
        signed_in_account.id, "circle-A", CircleRole.SIMPLIFIED_PATIENT
    )

    response = circle_client.get(
        "/test/circles/circle-A/anyone", headers=bearer(signed_in.access_token)
    )

    assert response.status_code == 200


def test_not_signed_in_is_401_not_403(circle_client, circle_access):
    circle_access.grant("user-1", "circle-A", CircleRole.MANAGER)

    response = circle_client.get("/test/circles/circle-A/today")

    assert response.status_code == 401


def test_signed_out_user_is_refused_even_if_still_a_member(
    circle_client, circle_access, signed_in, sessions, signed_in_account
):
    circle_access.grant(signed_in_account.id, "circle-A", CircleRole.MANAGER)
    sessions.sign_out(signed_in.session_id)

    response = circle_client.get(
        "/test/circles/circle-A/today", headers=bearer(signed_in.access_token)
    )

    assert response.status_code == 401
    assert response.get_json()["error"]["code"] == "session_revoked"


def test_default_circle_access_refuses_everyone():
    """With nothing connected, the app fails closed."""
    from app import create_app

    app = create_app("testing")  # no circle_access given -> DenyAll
    session = app.extensions["session_service"].create_session("user-1")

    @app.get("/test/circles/<circle_id>/today")
    @require_circle_role()
    def today(circle_id):
        return {}

    response = app.test_client().get(
        "/test/circles/circle-A/today", headers=bearer(session.access_token)
    )

    assert response.status_code == 403


@pytest.mark.parametrize(
    "mode, allowed",
    [(None, True), ("simplified", False), ("detailed", False)],
)
def test_manager_edits_only_an_offline_patient_photo(
    monkeypatch, mode, allowed
):
    """A patient with an account chooses their own picture, in any mode."""
    viewer = uuid4()
    patient = SimpleNamespace(
        account_id=None if mode is None else uuid4()
    )
    session = Mock()
    session.get.return_value = SimpleNamespace(app_mode=mode)
    monkeypatch.setattr(photo_routes, "_patient", lambda *_: patient)
    monkeypatch.setattr(
        photo_routes, "current_auth",
        lambda: SimpleNamespace(user_id=str(viewer)),
    )
    monkeypatch.setattr(
        photo_routes, "current_circle_role",
        lambda: CircleRole.MANAGER,
    )

    if allowed:
        assert photo_routes._patient_write(session, uuid4()) is patient
    else:
        with pytest.raises(NotFound):
            photo_routes._patient_write(session, uuid4())


@pytest.mark.parametrize(
    "role", [CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT]
)
def test_linked_patient_can_edit_own_portrait(monkeypatch, role):
    """Patient ownership is enough, regardless of their circle role."""
    viewer = uuid4()
    patient = SimpleNamespace(account_id=viewer)
    monkeypatch.setattr(photo_routes, "_patient", lambda *_: patient)
    monkeypatch.setattr(
        photo_routes, "current_auth",
        lambda: SimpleNamespace(user_id=str(viewer)),
    )
    monkeypatch.setattr(
        photo_routes, "current_circle_role",
        lambda: role,
    )

    assert photo_routes._patient_write(Mock(), uuid4()) is patient
