"""«سجّل جرعة الآن»: recording an extra dose, and the extra doses of some
days."""

from flask import jsonify

from app.auth.decorators import current_auth
from app.authz.decorators import require_circle_role
from app.database import transaction
from app.extensions import get_clock
from app.medications.blueprint import READ_ROLES, RECORD_ROLES, bp
from app.medications.extra_dose_list import extra_doses_between
from app.medications.extra_dose_view import extra_dose_response
from app.medications.extra_doses import MedicationExtraDoses
from app.medications.inputs import ExtraDoseRequest
from app.medications.route_helpers import occurrence_query, uuid_value
from app.validation import parse_json_body


@bp.post("/medication-extra-doses")
@require_circle_role(*RECORD_ROLES)
def record_extra_dose(circle_id):
    """Record a dose taken outside the dose times. It is always one more
    dose: it never answers a scheduled one."""
    body = parse_json_body(ExtraDoseRequest)
    circle, actor = uuid_value(circle_id), uuid_value(current_auth().user_id)
    with transaction() as session:
        doses = MedicationExtraDoses(session, get_clock().now())
        dose = doses.record(circle, actor, body)
        result = extra_dose_response(session, dose)
    return jsonify(medication_extra_dose=result), 201


@bp.get("/medication-extra-doses")
@require_circle_role(*READ_ROLES)
def list_extra_doses(circle_id):
    """The extra doses taken between two days of the patient's clock (at
    most 35 days), newest first, optionally of one medicine."""
    query = occurrence_query()
    plan_id = uuid_value(query.plan_id) if query.plan_id else None
    with transaction() as session:
        doses = extra_doses_between(
            session,
            uuid_value(circle_id),
            query.from_date,
            query.to_date,
            plan_id,
        )
    response = jsonify(medication_extra_doses=doses)
    response.headers["Cache-Control"] = "no-store"
    return response
