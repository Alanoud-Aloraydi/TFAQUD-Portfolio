"""PUT /api/v1/circles/<circle_id>/task-snoozes: «ذكّرني لاحقًا»."""

from flask import Blueprint, jsonify

from app.accounts import accounts_by_id
from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.background import run_at
from app.database import transaction
from app.extensions import get_clock
from app.medications.route_helpers import uuid_value
from app.snoozes.due import remind_due_now
from app.snoozes.inputs import SnoozeRequest
from app.snoozes.queries import snooze_response
from app.snoozes.service import SnoozeService
from app.validation import parse_json_body

bp = Blueprint(
    "snoozes",
    __name__,
    url_prefix="/api/v1/circles/<circle_id>",
)


@bp.put("/task-snoozes")
@require_circle_role(CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)
def snooze_task(circle_id):
    """Put a dose or a reading time off for some minutes, for the whole
    circle; answer who put it off and until when. At that time every other
    member is reminded (app/snoozes/due.py)."""
    body = parse_json_body(SnoozeRequest)
    now = get_clock().now()
    with transaction() as session:
        row = SnoozeService(session, now).snooze(
            uuid_value(circle_id), uuid_value(current_auth().user_id), body
        )
        accounts = accounts_by_id(session, {row.snoozed_by_account_id})
        value = snooze_response(row, accounts)
        remind_at = row.remind_at
    run_at(remind_at, now, remind_due_now)
    return jsonify(snooze=value)
