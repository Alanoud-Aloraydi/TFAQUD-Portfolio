"""The one JSON answer every error shares."""

from flask import g, jsonify


def error_response(
    status: int, code: str, message: str, details=None, retry_after=None
):
    """The JSON answer every error shares: a stable code, a message, the
    request id, optional details, and a Retry-After header when the client
    should wait.
    """
    # The stable code the app reads, a message, and the request id to find the
    # log line.
    body = {
        "error": {
            "code": code,
            "message": message,
            "request_id": g.get("request_id"),
        }
    }
    if details:
        body["error"]["details"] = details
    if retry_after is not None:
        body["error"]["retry_after_seconds"] = retry_after
    # Retry-After when the client should wait; a 401 says it wants a Bearer
    # token.
    response = jsonify(body)
    response.status_code = status
    if retry_after is not None:
        response.headers["Retry-After"] = str(retry_after)
    if status == 401:
        response.headers["WWW-Authenticate"] = "Bearer"
    return response
