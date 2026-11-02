"""Read prayer times for a circle's selected patient city."""

from datetime import datetime, timedelta, timezone
from uuid import UUID

from flask import Blueprint, jsonify
from sqlalchemy import select

from app.authz.decorators import require_circle_role
from app.authz.roles import CircleRole
from app.database import transaction
from app.errors import NotFound
from app.models import Patient
from app.prayer_times.service import prayer_times_for

bp = Blueprint("prayer_times", __name__, url_prefix="/api/v1/circles")
_RIYADH = timezone(timedelta(hours=3))


@bp.get("/<circle_id>/prayer-times")
@require_circle_role(CircleRole.MANAGER, CircleRole.SIMPLIFIED_PATIENT)
def prayer_times(circle_id: str):
    """Read the stored city before contacting the timetable provider."""
    with transaction() as session:
        city = session.scalar(
            select(Patient.city).where(
                Patient.care_circle_id == UUID(circle_id)
            )
        )
    if city is None:
        raise NotFound(code="circle_not_found")
    day = datetime.now(_RIYADH).date()
    response = jsonify(
        date=day.isoformat(),
        city=city,
        method="Umm al-Qura",
        timezone="Asia/Riyadh",
        timings=prayer_times_for(city, day),
    )
    response.headers["Cache-Control"] = "private, no-store"
    return response
