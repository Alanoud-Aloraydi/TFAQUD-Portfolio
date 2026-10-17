"""Session endpoints.

    POST /api/v1/auth/refresh    new access token from a refresh token
    POST /api/v1/auth/sign-out   end the current session
    GET  /api/v1/auth/session    who am I (needs a valid access token)

Sign-in itself (phone number and OTP) is feature F01. It will call
`SessionService.create_session` once the code is verified.
"""

from flask import Blueprint, jsonify

from app.auth.decorators import current_auth, require_auth
from app.extensions import get_session_service
from app.validation import Dto, parse_json_body

bp = Blueprint("auth", __name__, url_prefix="/api/v1/auth")


class RefreshRequest(Dto):
    refresh_token: str


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
    return jsonify(user_id=auth.user_id, session_id=auth.session_id)
