"""The errors the API chooses to return, one class per HTTP status."""


class ApiError(Exception):
    """An error the API chose to return. Subclasses fix the status code."""

    status = 400
    default_code = "bad_request"
    default_message = "The request could not be processed."

    def __init__(
        self, message=None, *, code=None, details=None, retry_after=None
    ):
        """Keep the message, the stable code the app reads, optional details
        per field, and how many seconds to wait before trying again.
        """
        self.message = message or self.default_message
        self.code = code or self.default_code
        self.details = details
        # Whole seconds the client should wait before trying again, or None.
        self.retry_after = retry_after
        super().__init__(self.message)


class BadRequest(ApiError):
    """400: the request cannot be read (not JSON, for example)."""
    status = 400
    default_code = "bad_request"
    default_message = "The request is malformed."


class Unauthorized(ApiError):
    """401: no valid sign-in."""
    status = 401
    default_code = "unauthorized"
    default_message = "Authentication is required."


class Forbidden(ApiError):
    """403: signed in, but not allowed to do this."""
    status = 403
    default_code = "forbidden"
    default_message = "You do not have access to this resource."


class NotFound(ApiError):
    """404: no such thing, or one the asker may not know exists."""
    status = 404
    default_code = "not_found"
    default_message = "The resource was not found."


class ValidationFailed(ApiError):
    """422: the request was read, but its values are not accepted."""
    status = 422
    default_code = "validation_error"
    default_message = "The request is not valid."


class Conflict(ApiError):
    """409: the data changed since the app read it."""
    status = 409
    default_code = "conflict"
    default_message = "The resource changed before this request completed."


class TooManyRequests(ApiError):
    """429: too many tries; `retry_after` says when to come back."""
    status = 429
    default_code = "too_many_requests"
    default_message = "Too many requests. Try again later."


class ServiceUnavailable(ApiError):
    """503: a service we depend on cannot answer now."""
    status = 503
    default_code = "service_unavailable"
    default_message = (
        "The service is not available right now. Try again later."
    )
