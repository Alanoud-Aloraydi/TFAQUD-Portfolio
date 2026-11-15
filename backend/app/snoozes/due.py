"""A task put off whose new time came: the circle is reminded once.

Two callers, the same work: a timer set when the task was put off
(`background.run_at`), and the scheduled tick, which also catches what a
timer lost when the server restarted. Each waiting row is claimed by one
UPDATE ... RETURNING, so the two never remind twice."""

import logging
from datetime import datetime, timedelta

from sqlalchemy import select, update

from app import metrics
from app.database import transaction
from app.extensions import get_clock
from app.models import Account, CareCircle, CareCircleManager, TaskSnooze
from app.push.notify import Push, notify
from app.snoozes.messages import snooze_message, unanswered_subject

log = logging.getLogger(__name__)

# A reminder this late (the server was off) is not sent any more.
_TOO_LATE = timedelta(hours=2)


def remind_due_now() -> None:
    """The timer's job: remind of every task whose new time has come."""
    send_due_snoozes(get_clock().now())


def send_due_snoozes(now: datetime) -> None:
    """Remind the circle of each task whose new time came by `now`, once;
    never raises."""
    with transaction() as session:
        claimed = list(
            session.execute(
                update(TaskSnooze)
                .where(
                    TaskSnooze.notified_at.is_(None),
                    TaskSnooze.remind_at <= now,
                )
                .values(notified_at=now)
                .returning(
                    TaskSnooze.care_circle_id,
                    TaskSnooze.task,
                    TaskSnooze.task_id,
                    TaskSnooze.scheduled_on,
                    TaskSnooze.time_of_day,
                    TaskSnooze.minutes,
                    TaskSnooze.remind_at,
                    TaskSnooze.snoozed_by_account_id,
                )
            )
        )
    for row in claimed:
        if now - row.remind_at > _TOO_LATE:
            continue
        try:
            _remind(row, now)
        except Exception:  # noqa: BLE001 - one task must not stop the rest
            log.warning("A task put off was not reminded.", exc_info=True)


def _remind(row, now: datetime) -> None:
    """Tell every member but the one who put it off (their phone reminds
    them itself), unless the task was recorded meanwhile."""
    with transaction() as session:
        patient = session.scalar(
            select(CareCircle).where(CareCircle.id == row.care_circle_id)
        )
        if patient is None:
            return
        subject = unanswered_subject(session, row, now)
        if subject is None:
            return
        recipients = set(
            session.scalars(
                select(CareCircleManager.account_id).where(
                    CareCircleManager.care_circle_id == row.care_circle_id
                )
            )
        )
        if patient.account_id is not None:
            recipients.add(patient.account_id)
        recipients.discard(row.snoozed_by_account_id)
        by = (
            session.get(Account, row.snoozed_by_account_id)
            if row.snoozed_by_account_id
            else None
        )
        by_name = by.display_name if by is not None else None
    if not recipients:
        return
    metrics.increment(f"snooze.{row.task}_due")
    notify(Push(tuple(recipients), snooze_message(row, subject, by_name)))
