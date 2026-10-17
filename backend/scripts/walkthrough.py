"""Shows the whole session life, one request at a time.

Run from the backend folder:

    python -m scripts.walkthrough

It starts the app in memory (no server, no network), uses the fake SMS sender and
a clock it can move, and prints every request and answer. Nothing is sent
anywhere.
"""

import json

from app import create_app
from app.clock import ManualClock

PHONE = "+966500000001"


def short(value):
    """Shorten tokens (long strings without spaces) so the output stays readable."""
    if isinstance(value, str) and len(value) > 40 and " " not in value:
        return value[:14] + "..."
    if isinstance(value, dict):
        return {k: short(v) for k, v in value.items()}
    if isinstance(value, list):
        return [short(v) for v in value]
    return value


def step(number, title):
    print(f"\n--- Step {number}: {title}")


def show(label, response):
    body = response.get_json(silent=True)
    text = json.dumps(short(body), ensure_ascii=False) if body is not None else "(no body)"
    print(f"    {label}\n    -> {response.status_code} {text}")


def bearer(token):
    return {"Authorization": f"Bearer {token}"}


def main():
    clock = ManualClock()
    app = create_app("development", clock=clock)
    client = app.test_client()
    sms = app.extensions["sms_sender"]
    sessions = app.extensions["session_service"]

    step(1, "The server is alive")
    show("GET /api/v1/health", client.get("/api/v1/health"))

    step(2, "Sign-in (this part belongs to feature F01; here it is done by hand)")
    sms.send(PHONE, "Your verification code is 4821")
    print(f"    The fake sender kept this instead of sending it: {sms.outbox[-1].message!r}")
    print("    The user types the code. The server accepts it and starts a session:")
    session = sessions.create_session("user-1")
    print(f"    access token  {session.access_token[:14]}...  valid until {session.access_token_expires_at:%H:%M}")
    print(f"    refresh token {session.refresh_token[:14]}...  valid until {session.refresh_token_expires_at:%Y-%m-%d}")

    step(3, "A protected request with the access token")
    show(
        "GET /api/v1/auth/session  (Authorization: Bearer <access token>)",
        client.get("/api/v1/auth/session", headers=bearer(session.access_token)),
    )

    step(4, "The same request without a token")
    show("GET /api/v1/auth/session", client.get("/api/v1/auth/session"))

    step(5, "A request with a wrong body (validation)")
    show("POST /api/v1/auth/refresh  {}", client.post("/api/v1/auth/refresh", json={}))

    step(6, "20 minutes pass: the access token has expired")
    clock.advance(minutes=20)
    show(
        "GET /api/v1/auth/session",
        client.get("/api/v1/auth/session", headers=bearer(session.access_token)),
    )

    step(7, "The app refreshes once and gets a new access token")
    refreshed = client.post("/api/v1/auth/refresh", json={"refresh_token": session.refresh_token})
    show("POST /api/v1/auth/refresh  {refresh_token}", refreshed)
    new_access = refreshed.get_json()["access_token"]
    show("GET /api/v1/auth/session (retry)", client.get("/api/v1/auth/session", headers=bearer(new_access)))

    step(8, "The user signs out")
    show("POST /api/v1/auth/sign-out", client.post("/api/v1/auth/sign-out", headers=bearer(new_access)))

    step(9, "After sign-out, nothing from that session works")
    show(
        "POST /api/v1/auth/refresh  (the old refresh token)",
        client.post("/api/v1/auth/refresh", json={"refresh_token": session.refresh_token}),
    )
    show(
        "GET /api/v1/auth/session  (the new access token, still inside its 15 minutes)",
        client.get("/api/v1/auth/session", headers=bearer(new_access)),
    )

    print("\nDone. Request ids, error codes and bodies above are exactly what the Flutter app will receive.")


if __name__ == "__main__":
    main()
