"""GET and DELETE /accounts/me: read the account, or delete it."""

from uuid import UUID

from flask import current_app, jsonify
from sqlalchemy import select

from app.auth.decorators import current_auth, require_auth
from app.circles.inputs import DeleteAccountInput
from app.circles.support import care_work
from app.database import transaction
from app.errors import NotFound
from app.extensions import get_user_store
from app.models import Account, CareCircle
from app.users.blueprint import bp
from app.validation import parse_optional_json_body


@bp.get("/me")
@require_auth
def read_account():
    """The signed-in account, as the account page needs it."""
    user = get_user_store().get(current_auth().user_id)
    if user is None:
        raise NotFound("This user does not exist.", code="user_not_found")
    account = user.to_dict()
    if "sqlalchemy" in current_app.extensions:
        with transaction() as session:
            stored = session.get(Account, UUID(user.id))
            account["avatar_code"] = stored.avatar_code if stored else None
    else:
        account["avatar_code"] = None
    # The app asks this before it shows the pages that create a circle for
    # the person's own care, so nobody fills them in for nothing.
    account["patient_circle_id"] = _patient_circle_id(user.id)
    response = jsonify(account=account)
    response.headers["Cache-Control"] = "no-store"
    return response


def _patient_circle_id(account_id: str) -> str | None:
    """The circle this account receives care in, or None.

    An account is the patient of at most one circle, so the answer is one id.
    """
    if "sqlalchemy" not in current_app.extensions:
        return None  # The in-memory mode of the unit tests has no circles.
    with transaction() as session:
        circle_id = session.scalar(
            select(CareCircle.id).where(
                CareCircle.account_id == UUID(account_id)
            )
        )
    return None if circle_id is None else str(circle_id)


@bp.delete("/me")
@require_auth
def delete_account():
    """Delete the account and end every sign-in of it.

    What happens to the account's care is decided by the body:
      - patient_choice "delete" deletes the circle the account is the
        patient of; "continue" keeps it, with the managers, under the
        account's name as text. It is required when the account is a
        patient.
      - delete_last_managed_circles true also deletes circles where the
        account is the only manager. Without it, such a circle blocks the
        deletion.
    An account with no circles can send no body.
    """
    body = parse_optional_json_body(DeleteAccountInput)
    with care_work() as work:
        work.care.delete_account(
            work.actor,
            patient_choice=body.patient_choice,
            delete_last_managed_circles=body.delete_last_managed_circles,
        )
    return "", 204
