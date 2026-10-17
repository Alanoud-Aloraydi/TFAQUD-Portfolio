"""Gives every request an id, so one failing request can be found in the logs.

The id is returned in the `X-Request-ID` header and inside every error body.
A client may send its own `X-Request-ID`; it is used only if it is short and
made of safe characters.
"""

import re
import uuid

from flask import Flask, g, request

_SAFE_REQUEST_ID = re.compile(r"[A-Za-z0-9_-]{1,64}")


def register_request_id(app: Flask) -> None:
    @app.before_request
    def assign_request_id():
        supplied = request.headers.get("X-Request-ID", "")
        # fullmatch: the whole value must fit the pattern. (`$` would also accept
        # a value that ends with a newline.)
        g.request_id = supplied if _SAFE_REQUEST_ID.fullmatch(supplied) else uuid.uuid4().hex

    @app.after_request
    def return_request_id(response):
        response.headers["X-Request-ID"] = g.get("request_id", "")
        return response
