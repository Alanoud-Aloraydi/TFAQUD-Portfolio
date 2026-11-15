"""Who asks for a sign-in code: the app's install id and the caller's
address."""

import re

from flask import current_app, request

_DEVICE_ID = re.compile(r"^[A-Za-z0-9-]{8,64}$")


def device_id() -> str | None:
    """The app's install id (X-Device-Id), when it looks like one."""
    value = request.headers.get("X-Device-Id", "").strip()
    return value if _DEVICE_ID.match(value) else None


def client_ip() -> str | None:
    """The caller's address: from CLIENT_IP_HEADER behind a proxy (Render
    puts it in CF-Connecting-IP), else the connection's own."""
    header = current_app.config.get("CLIENT_IP_HEADER")
    if header:
        value = request.headers.get(header, "").split(",")[0].strip()
        if value:
            return value[:64]
    return request.remote_addr
