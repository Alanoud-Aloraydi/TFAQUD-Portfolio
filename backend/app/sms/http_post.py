"""The default transport of the Authentica sender: a JSON POST with the
standard library that never follows a redirect, so the key never goes to
another address."""

import json
import urllib.error
import urllib.request


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    """Never follow a redirect: the key would go to the next address too."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        """Refuse every redirect."""
        return None


opener = urllib.request.build_opener(_NoRedirect)


def _parse_json(raw: bytes):
    """The JSON of an answer, or None when it cannot be read."""
    try:
        return json.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, ValueError):
        return None


def urllib_post(url: str, headers: dict, body: dict, timeout: float):
    """POST `body` as JSON. Returns (HTTP status, parsed JSON or None).

    A 4xx or 5xx answer is returned, not raised: it carries a status that the
    caller reads. A network problem is raised (OSError, HTTPException).
    """
    # The body as JSON, with the caller's headers (the key).
    request = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        method="POST",
        headers={
            **headers,
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
    )
    # Never follow a redirect (`opener`); a 4xx or 5xx comes back as its
    # status.
    try:
        with opener.open(request, timeout=timeout) as response:
            return response.status, _parse_json(response.read())
    except urllib.error.HTTPError as error:
        with error:
            return error.code, _parse_json(error.read())


def urllib_get(url: str, headers: dict, timeout: float):
    """GET `url`, the same way: (HTTP status, parsed JSON or None), with a
    4xx or 5xx returned and a network problem raised."""
    request = urllib.request.Request(
        url, method="GET", headers={**headers, "Accept": "application/json"}
    )
    try:
        with opener.open(request, timeout=timeout) as response:
            return response.status, _parse_json(response.read())
    except urllib.error.HTTPError as error:
        with error:
            return error.code, _parse_json(error.read())
