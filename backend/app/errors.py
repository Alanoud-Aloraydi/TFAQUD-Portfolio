"""One error format for the whole API.

Every error response has this shape:

    {
      "error": {
        "code": "validation_error",       <- stable, for the app to act on
        "message": "The request is not valid.",   <- for developers and logs
        "request_id": "3f2a...",
        "details": [ {"field": "...", "code": "...", "message": "..."} ]   <- optional
      }
    }

The Flutter app decides what to do from `code` (and shows its own Arabic text).
`message` is English and is not meant for the end user.
"""

from flask import Flask, g, jsonify
from werkzeug.exceptions import HTTPException


class ApiError(Exception):
    """An error the API chose to return. Subclasses fix the status code."""

    status = 400
    default_code = "bad_request"
    default_message = "The request could not be processed."

    def __init__(self, message=None, *, code=None, details=None):
        self.message = message or self.default_message
        self.code = code or self.default_code
        self.details = details
        super().__init__(self.message)


class BadRequest(ApiError):
    status = 400
    default_code = "bad_request"
    default_message = "The request is malformed."


class Unauthorized(ApiError):
    status = 401
    default_code = "unauthorized"
    default_message = "Authentication is required."


class Forbidden(ApiError):
    status = 403
    default_code = "forbidden"
    default_message = "You do not have access to this resource."


class NotFound(ApiError):
    status = 404
    default_code = "not_found"
    default_message = "The resource was not found."


class ValidationFailed(ApiError):
    status = 422
    default_code = "validation_error"
    default_message = "The request is not valid."


# Standard HTTP errors raised by Flask itself (unknown URL, wrong method, ...)
# are returned in the same format, with these codes.
_HTTP_CODES = {
    400: "bad_request",
    404: "not_found",
    405: "method_not_allowed",
    413: "payload_too_large",
    415: "unsupported_media_type",
}


def error_response(status: int, code: str, message: str, details=None):
    body = {
        "error": {
            "code": code,
            "message": message,
            "request_id": g.get("request_id"),
        }
    }
    if details:
        body["error"]["details"] = details
    response = jsonify(body)
    response.status_code = status
    if status == 401:
        response.headers["WWW-Authenticate"] = "Bearer"
    return response


def register_error_handlers(app: Flask) -> None:
    @app.errorhandler(ApiError)
    def handle_api_error(error: ApiError):
        return error_response(error.status, error.code, error.message, error.details)

    @app.errorhandler(HTTPException)
    def handle_http_exception(error: HTTPException):
        code = _HTTP_CODES.get(error.code, "http_error")
        response = error_response(error.code, code, error.description or error.name)
        # A 405 must tell the client which methods are allowed.
        for name, value in error.get_headers():
            if name.lower() == "allow":
                response.headers["Allow"] = value
        return response

    @app.errorhandler(Exception)
    def handle_unexpected_error(error: Exception):
        # The traceback goes to the log. The client never sees it.
        app.logger.exception("Unhandled error (request_id=%s)", g.get("request_id"))
        return error_response(500, "internal_error", "An unexpected error occurred.")
