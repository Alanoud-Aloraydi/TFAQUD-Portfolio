"""Session and sign-in endpoints.

    POST /api/v1/auth/refresh    new access token from a refresh token
    POST /api/v1/auth/sign-out   end the current session
    GET  /api/v1/auth/session    who am I (needs a valid access token)

    POST /api/v1/auth/request-code   send a sign-in code by SMS (F01)
    POST /api/v1/auth/verify-code    check the code and sign in (F01)

The rules of the two sign-in endpoints are in `app/auth/sign_in.py`.
"""

from flask import Blueprint, jsonify

from app.auth.decorators import current_auth, require_auth
from app.auth.inputs import Code, Phone, VerificationId
from app.extensions import get_session_service, get_sign_in_service
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


@bp.post("/request-code")
def request_code():
    body = parse_json_body(RequestCodeRequest)
    verification_id = get_sign_in_service().request_code(body.phone_number, body.verification_id)
    return jsonify(verification_id=verification_id)


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
    return jsonify(account_id=auth.user_id, session_id=auth.session_id)
