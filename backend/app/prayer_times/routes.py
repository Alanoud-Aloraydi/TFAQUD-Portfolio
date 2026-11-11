"""Read prayer times for a circle's patient, in the patient's own zone."""

from uuid import UUID

from flask import Blueprint, jsonify

from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.clock import patient_today
from app.database import transaction
from app.errors import NotFound
from app.extensions import get_clock
from app.models import Account, CareCircle
from app.prayer_times.service import prayer_times_for

bp = Blueprint("prayer_times", __name__, url_prefix="/api/v1/circles")


@bp.get("/<circle_id>/prayer-times")
@require_circle_role(
    CircleRole.MANAGER,
    CircleRole.SIMPLIFIED_PATIENT,
    CircleRole.MEMBER,
)
def prayer_times(circle_id: str):
    """Read the stored city and zone before contacting the provider.

    `date` is the patient's today and `timings` are wall clock there."""
    # The patient's city and zone first, without holding the transaction
    # while Aladhan answers.
    with transaction() as session:
        patient = session.get(CareCircle, UUID(circle_id))
        if patient is None:
            raise NotFound(code="circle_not_found")
        # A patient with an account keeps the city on the account.
        holder = (
            session.get(Account, patient.account_id)
            if patient.account_id else patient
        )
        city, zone = holder.city, patient.time_zone
        # Today's five times in the patient's own day, not kept by any cache
        # on the way.
        day = patient_today(patient, get_clock().now())
    response = jsonify(
        date=day.isoformat(),
        city=city,
        timezone=zone,
        timings=prayer_times_for(city, zone, day),
    )
    response.headers["Cache-Control"] = "private, no-store"
    return response
