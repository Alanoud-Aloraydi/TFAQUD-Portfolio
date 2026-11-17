"""The doses of some days, and recording one."""

from datetime import date

from flask import jsonify

from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.database import transaction
from app.errors import NotFound
from app.extensions import get_clock
from app.medications.blueprint import READ_ROLES, RECORD_ROLES, bp
from app.medications.doses import MedicationDoseService
from app.medications.inputs import DoseRecordRequest
from app.medications.queries import MedicationQueries
from app.medications.route_helpers import (
    dose_record_response,
    occurrence_query,
    uuid_value,
)
from app.push.messages.attention import send_all
from app.push.messages.attention_events import skipped_dose_pushes
from app.validation import parse_json_body


@bp.get("/medication-occurrences")
@require_circle_role(*READ_ROLES)
def list_occurrences(circle_id):
    """The doses due between two dates (at most 35 days), each with its record
    when there is one.
    """
    query = occurrence_query()
    plan_id = uuid_value(query.plan_id) if query.plan_id else None
    with transaction() as session:
        occurrences = MedicationQueries(
            session, get_clock().now()
        ).occurrences(
            uuid_value(circle_id),
            query.from_date,
            query.to_date,
            plan_id,
        )
    response = jsonify(medication_occurrences=occurrences)
    response.headers["Cache-Control"] = "no-store"
    return response


@bp.put("/medication-dose-records/<schedule_id>/<scheduled_on>")
@require_circle_role(*RECORD_ROLES)
def record_dose(circle_id, schedule_id, scheduled_on):
    """Record one dose as taken or skipped. Sending the same record again
    changes nothing; a different one for a dose already recorded is a conflict.
    """
    # A date that cannot be read names no dose.
    try:
        dose_date = date.fromisoformat(scheduled_on)
    except (TypeError, ValueError):
        raise NotFound() from None
    body = parse_json_body(DoseRecordRequest)
    circle, actor = uuid_value(circle_id), uuid_value(current_auth().user_id)
    with transaction() as session:
        service = MedicationDoseService(session, get_clock().now())
        record = service.record(
            circle, uuid_value(schedule_id), dose_date, actor, body
        )
        result = dose_record_response(session, record)
        # A new skip is told to the others; the same record again is not.
        pushes = (
            skipped_dose_pushes(session, circle, record, actor)
            if service.created else []
        )
    send_all(pushes)
    return jsonify(medication_dose_record=result)
