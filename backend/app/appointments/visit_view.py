"""A visit paper as the API answers it."""

from app.models import AppointmentVisit


def visit_view(visit: AppointmentVisit | None) -> dict | None:
    """Exclude audio bytes from the JSON visit representation."""
    if visit is None:
        return None
    return {
        "appointment_id": str(visit.appointment_id),
        "summary": visit.summary,
        "recommendations": visit.recommendations,
        "follow_up": visit.follow_up,
        "has_audio": visit.audio is not None,
    }
