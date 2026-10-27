"""Browser access (CORS) exists only in development, and only for this computer."""

import pytest

from app import create_app

ORIGIN = "http://localhost:53012"
URL = "/api/v1/auth/request-code"


def preflight(client, origin=ORIGIN):
    return client.options(
        URL,
        headers={
            "Origin": origin,
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "authorization,content-type",
        },
    )


@pytest.fixture
def dev_client():
    return create_app("development").test_client()


def test_the_browser_check_before_a_call_is_answered(dev_client):
    response = preflight(dev_client)

    assert response.status_code in (200, 204)
    assert response.headers["Access-Control-Allow-Origin"] == ORIGIN
    allowed_headers = response.headers["Access-Control-Allow-Headers"].lower()
    assert "authorization" in allowed_headers and "content-type" in allowed_headers
    assert "POST" in response.headers["Access-Control-Allow-Methods"]
    assert "PUT" in response.headers["Access-Control-Allow-Methods"]


def test_the_browser_may_use_every_method_the_api_has(dev_client):
    # A method missing here is blocked by Chrome before the call leaves the
    # page, and the app only sees "no internet connection".
    used = {
        method
        for rule in dev_client.application.url_map.iter_rules()
        for method in rule.methods
    } - {"HEAD", "OPTIONS"}

    header = preflight(dev_client).headers["Access-Control-Allow-Methods"]
    allowed = {method.strip() for method in header.split(",")}

    assert used - allowed == set()


@pytest.mark.parametrize(
    "origin",
    ["http://localhost:5000", "http://127.0.0.1:8080", "https://localhost", "http://localhost"],
)
def test_addresses_of_this_computer_are_allowed(dev_client, origin):
    response = dev_client.get("/api/v1/health", headers={"Origin": origin})

    assert response.headers["Access-Control-Allow-Origin"] == origin


def test_error_answers_carry_the_headers_too(dev_client):
    # The page can only read an error if the error answer is allowed as well.
    response = dev_client.post(URL, json={}, headers={"Origin": ORIGIN})

    assert response.status_code == 422
    assert response.headers["Access-Control-Allow-Origin"] == ORIGIN


def test_the_page_can_read_the_retry_after_and_request_id_headers(dev_client):
    response = dev_client.get("/api/v1/health", headers={"Origin": ORIGIN})

    exposed = response.headers["Access-Control-Expose-Headers"]
    assert "Retry-After" in exposed and "X-Request-ID" in exposed


@pytest.mark.parametrize(
    "origin",
    [
        "https://evil.example",
        "http://localhost.evil.example",
        "http://evil.example/localhost",
        "http://localhost:5000.evil.example",
        "null",
        "",
    ],
)
def test_other_websites_are_not_allowed(dev_client, origin):
    response = dev_client.get("/api/v1/health", headers={"Origin": origin})

    assert "Access-Control-Allow-Origin" not in response.headers


def test_a_call_without_an_origin_gets_no_cors_headers(dev_client):
    response = dev_client.get("/api/v1/health")

    assert "Access-Control-Allow-Origin" not in response.headers


@pytest.mark.parametrize("env", ["testing", "staging"])
def test_no_other_environment_sends_the_headers(monkeypatch, env):
    monkeypatch.setenv("SECRET_KEY", "x" * 40)
    client = create_app(env).test_client()

    response = client.get("/api/v1/health", headers={"Origin": ORIGIN})

    assert "Access-Control-Allow-Origin" not in response.headers
    assert "Access-Control-Allow-Methods" not in preflight(client).headers
