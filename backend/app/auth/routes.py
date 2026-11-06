"""Session and sign-in endpoints.

    POST /api/v1/auth/refresh    new access token from a refresh token
    POST /api/v1/auth/sign-out   end the current session
    GET  /api/v1/auth/session    who am I (needs a valid access token)

    POST /api/v1/auth/request-code   send a sign-in code by SMS (F01)
    POST /api/v1/auth/verify-code    check the code and sign in (F01)

The rules of the two sign-in endpoints are in `app/auth/sign_in.py`.
"""

import re

from flask import Blueprint, current_app, jsonify, request

from app.auth.decorators import current_auth, require_auth
from app.auth.inputs import Code, Phone, VerificationId
from app.extensions import (
    get_session_service,
    get_sign_in_service,
    get_user_store,
)
from app.errors import Unauthorized
from app.validation import Dto, parse_json_body

bp = Blueprint("auth", __name__, url_prefix="/api/v1/auth")


class RefreshRequest(Dto):
    refresh_token: str


class RequestCodeRequest(Dto):
    phone_number: Phone
    # Send it back to ask for another SMS inside the same request (a resend).
    verification_id: VerificationId | None = None


class VerifyCodeRequest(Dto):
    verification_id: VerificationId
    code: Code


_DEVICE_ID = re.compile(r"^[A-Za-z0-9-]{8,64}$")


def _device_id() -> str | None:
    """The app's install id (X-Device-Id), when it looks like one."""
    value = request.headers.get("X-Device-Id", "").strip()
    return value if _DEVICE_ID.match(value) else None


def _client_ip() -> str | None:
    """The caller's address: from CLIENT_IP_HEADER behind a proxy (Render
    puts it in CF-Connecting-IP), else the connection's own."""
    header = current_app.config.get("CLIENT_IP_HEADER")
    if header:
        value = request.headers.get(header, "").split(",")[0].strip()
        if value:
            return value[:64]
    return request.remote_addr


@bp.post("/request-code")
def request_code():
    body = parse_json_body(RequestCodeRequest)
    sent = get_sign_in_service().send_code(
        body.phone_number,
        body.verification_id,
        device_id=_device_id(),
        client_ip=_client_ip(),
    )
    return jsonify(
        verification_id=sent.request_id,
        resend_after_seconds=sent.resend_after_seconds,
    )


@bp.post("/verify-code")
def verify_code():
    body = parse_json_body(VerifyCodeRequest)
    result = get_sign_in_service().verify_code(body.verification_id, body.code)
    session = result.session
    return jsonify(
        access_token=session.access_token,
        access_token_expires_at=session.access_token_expires_at.isoformat(),
        refresh_token=session.refresh_token,
        refresh_token_expires_at=session.refresh_token_expires_at.isoformat(),
        account=result.user.to_dict(),
    )


@bp.post("/refresh")
def refresh():
    body = parse_json_body(RefreshRequest)
    issued = get_session_service().refresh(body.refresh_token)
    return jsonify(
        access_token=issued.access_token,
        access_token_expires_at=issued.access_token_expires_at.isoformat(),
    )


@bp.post("/sign-out")
@require_auth
def sign_out():
    get_session_service().sign_out(current_auth().session_id)
    return "", 204


@bp.get("/session")
@require_auth
def session_info():
    auth = current_auth()
    user = get_user_store().get(auth.user_id)
    if user is None:
        raise Unauthorized(code="session_revoked")
    return jsonify(
        account_id=auth.user_id,
        session_id=auth.session_id,
        account=user.to_dict(),
    )
