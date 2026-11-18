"""PUT /accounts/me/profile: save the account's names, birth date and
city."""

from flask import jsonify

from app.auth.decorators import current_auth, require_auth
from app.clock import latest_today
from app.errors import NotFound, ValidationFailed
from app.extensions import get_clock, get_user_store
from app.users.age import require_old_enough
from app.users.blueprint import bp
from app.users.profile_input import ProfileRequest
from app.validation import parse_json_body


@bp.put("/me/profile")
@require_auth
def save_profile():
    """Save the signed-in account's names, and birth date and city if sent.

    Called by onboarding (all five fields) and the account page (names
    only). A birth date in the future is refused with
    ``invalid_birth_date``. Returns the saved account.
    """
    # A birth date in the future is refused; then the account's profile is
    # saved.
    body = parse_json_body(ProfileRequest)
    # No patient, so no zone yet: only a day that is still ahead
    # everywhere is in the future. A circle checks it again in the
    # patient's own zone (`CareService`).
    today = latest_today(get_clock().now())
    if body.birth_date and body.birth_date > today:
        raise ValidationFailed(
            "The birth date cannot be in the future.",
            code="invalid_birth_date",
        )
    if body.birth_date:
        require_old_enough(body.birth_date, today)
    user = get_user_store().update_profile(
        current_auth().user_id,
        body.first_name,
        body.last_name,
        body.display_name,
        birth_date=body.birth_date,
        city=body.city,
    )
    if user is None:
        raise NotFound("This user does not exist.", code="user_not_found")
    return jsonify(account=user.to_dict())
