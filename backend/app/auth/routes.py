"""The session and sign-in endpoints under /api/v1/auth, and who asks for a
sign-in code (the app's install id and the caller's address)."""

import re

from flask import Blueprint, current_app, jsonify, request

from app.auth.decorators import current_auth, require_auth
from app.auth.inputs import (
    RefreshRequest,
    RequestCodeRequest,
    VerifyCodeRequest,
)
from app.errors import Unauthorized
from app.extensions import (
    get_session_service,
    get_sign_in_service,
    get_user_store,
)
from app.validation import parse_json_body


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


bp = Blueprint("auth", __name__, url_prefix="/api/v1/auth")


@bp.post("/request-code")
def request_code():
    """Send a sign-in code to the phone number, a new request or a resend;
    answer the request's id and when another code may come.
    """
    body = parse_json_body(RequestCodeRequest)
    sent = get_sign_in_service().send_code(
        body.phone_number,
        body.verification_id,
        device_id=device_id(),
        client_ip=client_ip(),
    )
    return jsonify(
        verification_id=sent.request_id,
        resend_after_seconds=sent.resend_after_seconds,
    )


@bp.post("/verify-code")
def verify_code():
    """Check the typed code; when it is right, start a session and answer its
    tokens and the account.
    """
    body = parse_json_body(VerifyCodeRequest)
    result = get_sign_in_service().verify_code(body.verification_id, body.code)
    session = result.session
    return jsonify(
        access_token=session.access_token,
        access_token_expires_at=session.access_token_expires_at.isoformat(),
        refresh_token=session.refresh_token,
        account=result.user.to_dict(),
    )


@bp.post("/refresh")
def refresh():
    """A new access token for a live refresh token."""
    body = parse_json_body(RefreshRequest)
    issued = get_session_service().refresh(body.refresh_token)
    return jsonify(
        access_token=issued.access_token,
        access_token_expires_at=issued.access_token_expires_at.isoformat(),
    )


@bp.post("/sign-out")
@require_auth
def sign_out():
    """End this sign-in session."""
    get_session_service().sign_out(current_auth().session_id)
    return "", 204


@bp.get("/session")
@require_auth
def session_info():
    """Who is signed in on this session: the account and session ids, and the
    account.
    """
    auth = current_auth()
    user = get_user_store().get(auth.user_id)
    if user is None:
        raise Unauthorized(code="session_revoked")
    return jsonify(
        account_id=auth.user_id,
        session_id=auth.session_id,
        account=user.to_dict(),
    )
