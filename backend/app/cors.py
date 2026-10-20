"""Browser access for local development only.

A Flutter web app running in Chrome is served from its own address, for example
http://localhost:53012. The browser refuses its calls to the API at
http://localhost:5000 unless the API says it allows them. This is a browser rule
(CORS). The iPhone app is not a browser and does not need it.

This is switched on only when APP_ENV is `development`. In `testing`, `staging`
and `production` the headers are never sent. Even in development only the
addresses of this computer (localhost, 127.0.0.1) are allowed, so another
website open in the same browser cannot read the answers.
"""

import re

from flask import Flask, request

# http or https, then localhost or 127.0.0.1, then an optional port.
_LOCAL_ORIGIN = re.compile(r"^https?://(localhost|127\.0\.0\.1)(:[0-9]{1,5})?$")

_ALLOWED_HEADERS = "Authorization, Content-Type, X-Request-ID"
_ALLOWED_METHODS = "GET, POST, PUT, DELETE, OPTIONS"
# Headers the page may read from an answer (a browser hides all others).
_EXPOSED_HEADERS = "X-Request-ID, Retry-After"
_PREFLIGHT_CACHE_SECONDS = "600"


def register_development_cors(app: Flask) -> None:
    @app.after_request
    def add_cors_headers(response):
        origin = request.headers.get("Origin", "")
        # The answer depends on the Origin header, so caches must know it.
        response.vary.add("Origin")
        if _LOCAL_ORIGIN.fullmatch(origin):
            response.headers["Access-Control-Allow-Origin"] = origin
            response.headers["Access-Control-Allow-Headers"] = _ALLOWED_HEADERS
            response.headers["Access-Control-Allow-Methods"] = _ALLOWED_METHODS
            response.headers["Access-Control-Expose-Headers"] = _EXPOSED_HEADERS
            response.headers["Access-Control-Max-Age"] = _PREFLIGHT_CACHE_SECONDS
        return response
