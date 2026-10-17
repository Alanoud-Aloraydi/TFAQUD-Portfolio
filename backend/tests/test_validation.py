"""Request validation, shown on the refresh endpoint (its body is one field)."""

import pytest


def post_refresh(client, **kwargs):
    return client.post("/api/v1/auth/refresh", **kwargs)


def test_body_that_is_not_json_is_rejected(client):
    response = post_refresh(client, data="refresh_token=abc")

    assert response.status_code == 400
    assert response.get_json()["error"]["code"] == "invalid_json"


def test_malformed_json_is_rejected(client):
    response = post_refresh(client, data="{not json", content_type="application/json")

    assert response.status_code == 400
    assert response.get_json()["error"]["code"] == "invalid_json"


def test_empty_object_reports_the_missing_field(client):
    response = post_refresh(client, json={})

    assert response.status_code == 422
    error = response.get_json()["error"]
    assert error["code"] == "validation_error"
    assert error["details"] == [
        {"field": "refresh_token", "code": "missing", "message": "Field required"}
    ]


def test_wrong_type_is_rejected(client):
    response = post_refresh(client, json={"refresh_token": 12345})

    assert response.status_code == 422
    assert response.get_json()["error"]["details"][0]["field"] == "refresh_token"


def test_unknown_field_is_rejected(client):
    response = post_refresh(client, json={"refresh_token": "abc", "extra": "x"})

    assert response.status_code == 422
    assert response.get_json()["error"]["details"][0]["field"] == "extra"


@pytest.mark.parametrize("body", [[], "text", 5])
def test_body_that_is_not_an_object_is_rejected(client, body):
    response = post_refresh(client, json=body)

    assert response.status_code == 422
    assert response.get_json()["error"]["details"][0]["field"] == "body"


def test_error_does_not_echo_the_value_that_was_sent(client):
    secret_value = "very-secret-value-0000"
    response = post_refresh(client, json={"refresh_token": 1234, "other": secret_value})

    assert secret_value not in response.get_data(as_text=True)
    assert "1234" not in response.get_data(as_text=True)
