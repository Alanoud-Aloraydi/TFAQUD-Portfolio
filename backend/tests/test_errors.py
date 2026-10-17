"""Every error has the same shape (see app/errors.py)."""

import pytest

from app.errors import Forbidden, NotFound


def assert_error_shape(response, status, code):
    assert response.status_code == status
    assert response.is_json
    error = response.get_json()["error"]
    assert error["code"] == code
    assert isinstance(error["message"], str) and error["message"]
    assert error["request_id"] == response.headers["X-Request-ID"]
    return error


def test_unknown_url_uses_the_error_format(client):
    response = client.get("/api/v1/does-not-exist")

    assert_error_shape(response, 404, "not_found")


def test_wrong_method_uses_the_error_format_and_lists_allowed_methods(client):
    response = client.post("/api/v1/health")

    assert_error_shape(response, 405, "method_not_allowed")
    assert "GET" in response.headers["Allow"]


def test_api_error_uses_the_error_format(app, client):
    @app.get("/boom/not-found")
    def not_found():
        raise NotFound("No such thing.")

    @app.get("/boom/forbidden")
    def forbidden():
        raise Forbidden(code="custom_code", details=[{"field": "x", "message": "y"}])

    assert_error_shape(client.get("/boom/not-found"), 404, "not_found")
    error = assert_error_shape(client.get("/boom/forbidden"), 403, "custom_code")
    assert error["details"] == [{"field": "x", "message": "y"}]


def test_unexpected_exception_returns_500_without_leaking_details(app, client):
    @app.get("/boom/crash")
    def crash():
        raise RuntimeError("secret internal detail")

    response = client.get("/boom/crash")

    error = assert_error_shape(response, 500, "internal_error")
    assert "secret internal detail" not in response.get_data(as_text=True)
    assert "Traceback" not in response.get_data(as_text=True)
    assert "details" not in error


def test_401_carries_the_www_authenticate_header(client):
    response = client.get("/api/v1/auth/session")

    assert_error_shape(response, 401, "missing_token")
    assert response.headers["WWW-Authenticate"] == "Bearer"


def test_every_response_has_a_request_id(client):
    first = client.get("/api/v1/health").headers["X-Request-ID"]
    second = client.get("/api/v1/health").headers["X-Request-ID"]

    assert first and second and first != second


def test_a_safe_client_request_id_is_kept(client):
    response = client.get("/api/v1/health", headers={"X-Request-ID": "abc-123_XYZ"})

    assert response.headers["X-Request-ID"] == "abc-123_XYZ"


@pytest.mark.parametrize(
    "unsafe", ["has space", "x" * 65, "line\nbreak", "ends-with-newline\n", "<script>"]
)
def test_an_unsafe_client_request_id_is_replaced(client, unsafe):
    # The header is sent directly through the WSGI environ so that characters a
    # real HTTP client would refuse can still be tested.
    response = client.get("/api/v1/health", environ_overrides={"HTTP_X_REQUEST_ID": unsafe})

    assert response.headers["X-Request-ID"] != unsafe
    assert len(response.headers["X-Request-ID"]) == 32
