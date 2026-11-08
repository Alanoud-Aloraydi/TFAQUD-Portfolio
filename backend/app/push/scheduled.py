"""The scheduled tick: a dose or measurement that was missed, each told
once to the circle and logged so a repeat tick never resends it.

The reminders before a dose, a measurement or an appointment (at its time,
and for an appointment a day before and two hours before) are set on each
phone by the app itself, so they come on time without this tick and without
the server. The server tells only what a phone cannot know ahead: that a
task's time passed and nothing was recorded.

Called by `/internal/tick` on an external schedule (see README). Never
raises: a failed scan or send is logged and the tick moves on, so one bad
circle never blocks the rest.
"""

import logging
from datetime import datetime
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import transaction
from app.medications.queries import MedicationQueries
from app.measurements.queries import MeasurementQueries
from app.models import (
    CareCircle,
    CareCircleManager,
    NotificationLog,
    Patient,
)
from app.push.notify import Push, notify
from app.push.sender import PushMessage

log = logging.getLogger(__name__)
RIYADH = ZoneInfo("Asia/Riyadh")


def run_tick(now: datetime) -> None:
    """Scan every circle once; swallow one circle's error."""
    with transaction() as session:
        circle_ids = list(session.scalars(select(CareCircle.id)))
    for circle_id in circle_ids:
        try:
            _scan_doses(circle_id, now)
            _scan_measurements(circle_id, now)
        except Exception:  # noqa: BLE001 - one circle must not stop the rest
            log.warning(
                "Scheduled scan failed for a circle.", exc_info=True
            )


def _claim(dedupe_key: str) -> bool:
    """True the first time `dedupe_key` is claimed; False on a repeat."""
    try:
        with transaction() as session:
            session.add(NotificationLog(dedupe_key=dedupe_key))
    except IntegrityError:
        return False
    return True


def _circle_recipients(session: Session, circle_id: UUID) -> tuple[UUID, ...]:
    """Every manager of the circle, plus its patient if they have one."""
    recipients = set(
        session.scalars(
            select(CareCircleManager.account_id).where(
                CareCircleManager.care_circle_id == circle_id
            )
        )
    )
    patient = session.scalar(
        select(Patient).where(Patient.care_circle_id == circle_id)
    )
    if patient is not None and patient.account_id is not None:
        recipients.add(patient.account_id)
    return tuple(recipients)


def _scan_doses(circle_id: UUID, now: datetime) -> None:
    today = now.astimezone(RIYADH).date()
    with transaction() as session:
        occurrences = MedicationQueries(session, now).occurrences(
            circle_id, today, today
        )
        recipients = _circle_recipients(session, circle_id)
    for occurrence in occurrences:
        if (
            occurrence["record"] is not None
            or occurrence["timing_state"] != "missed"
        ):
            continue
        key = (
            f"dose_missed:{occurrence['schedule_id']}:"
            f"{occurrence['scheduled_on']}"
        )
        if not _claim(key):
            continue
        # «ما تسجّلت» says only what the app knows: the dose may have been
        # taken and not recorded.
        notify(
            Push(
                recipients,
                PushMessage(
                    "جرعة ما تسجّلت",
                    f"جرعة {occurrence['name']} ما تسجّلت للحين. "
                    "تقدر تسجّلها من تفقّد.",
                    "dose_missed",
                ),
            )
        )


def _scan_measurements(circle_id: UUID, now: datetime) -> None:
    today = now.astimezone(RIYADH).date()
    with transaction() as session:
        occurrences = MeasurementQueries(session, now).occurrences(
            circle_id, today, today
        )
        recipients = _circle_recipients(session, circle_id)
    for occurrence in occurrences:
        if occurrence["status"] != "missed":
            continue
        kind_name = "سكر الدم" if occurrence["kind"] == "glucose" else (
            "ضغط الدم"
        )
        # One alert per reading time of the day.
        key = (
            f"measurement_missed:{occurrence['version_id']}:"
            f"{occurrence['scheduled_on']}:{occurrence['time_of_day']}"
        )
        if not _claim(key):
            continue
        notify(
            Push(
                recipients,
                PushMessage(
                    "قياس ما تسجّل",
                    f"قياس {kind_name} ما تسجّل للحين. "
                    "تقدر تسجّله من تفقّد.",
                    "measurement_missed",
                ),
            )
        )
