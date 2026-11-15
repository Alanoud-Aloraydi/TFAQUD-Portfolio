"""`run_tick`: one pass of the scheduled scan."""

import logging
from datetime import datetime

from sqlalchemy import select

from app.database import transaction
from app.models import CareCircle
from app.push.scheduled.appointments import scan_appointments
from app.push.scheduled.doses import scan_doses
from app.push.scheduled.measurements import scan_measurements
from app.push.scheduled.purge import purge_old_rows
from app.snoozes.due import send_due_snoozes

log = logging.getLogger(__name__)


def run_tick(now: datetime) -> None:
    """Remind of the tasks put off whose time came, delete the rows past
    their time, then scan every circle once; swallow one circle's error."""
    try:
        send_due_snoozes(now)
    except Exception:  # noqa: BLE001 - the scan must still run
        log.warning("Tasks put off were not reminded.", exc_info=True)
    try:
        purge_old_rows(now)
    except Exception:  # noqa: BLE001 - the scan must still run
        log.warning("Purging old rows failed.", exc_info=True)
    with transaction() as session:
        circle_ids = list(session.scalars(select(CareCircle.id)))
    for circle_id in circle_ids:
        try:
            scan_doses(circle_id, now)
            scan_measurements(circle_id, now)
            scan_appointments(circle_id, now)
        except Exception:  # noqa: BLE001 - one circle must not stop the rest
            log.warning(
                "Scheduled scan failed for a circle.", exc_info=True
            )
