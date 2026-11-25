"""A task put off whose new time came: the circle is reminded once, with
what the reminder says and which task it is about.

Two callers, the same work: a timer set when the task was put off
(`background.run_at`), and the scheduled scan, which catches what a
restart lost."""

import logging
from datetime import datetime, time, timedelta

from sqlalchemy import select, update

from app import metrics
from app.database import transaction
from app.extensions import get_clock
from app.measurements.queries import MeasurementQueries
from app.medications.queries import MedicationQueries
from app.models import Account, CareCircle, CareCircleManager, TaskSnooze
from app.push.notify import Push, notify
from app.push.sender import PushMessage
from app.push.notify import dose_target, measurement_target

log = logging.getLogger(__name__)


def minutes_text(minutes: int) -> str:
    """«دقيقة», «دقيقتين», «5 دقائق», «15 دقيقة», «ساعة», «ساعتين»,
    «3 ساعات», «11 ساعة», «ساعة و30 دقيقة»: the Arabic count of a time put
    off (up to 12 hours)."""
    hours, rest = divmod(minutes, 60)
    if hours == 0:
        return _count(rest, "دقيقة", "دقيقتين", "دقائق")
    whole = _count(hours, "ساعة", "ساعتين", "ساعات")
    if rest == 0:
        return whole
    return f"{whole} و{_count(rest, 'دقيقة', 'دقيقتين', 'دقائق')}"


def _count(number: int, one: str, two: str, few: str) -> str:
    """An Arabic count: «ساعة», «ساعتين», «3 ساعات», «11 ساعة»."""
    if number == 1:
        return one
    if number == 2:
        return two
    if number <= 10:
        return f"{number} {few}"
    return f"{number} {one}"


def clock_text(moment: time) -> str:
    """«8:00 ص», «5:45 م»: a wall time as the app shows it."""
    hour = moment.hour % 12 or 12
    half = "ص" if moment.hour < 12 else "م"
    return f"{hour}:{moment.minute:02d} {half}"


# What a reading recorded or skipped says in its status.
ANSWERED = {"read", "read_late", "skipped"}


def unanswered_subject(session, row, now: datetime) -> str | None:
    """The medicine's name or the reading's kind, while the task is still
    not recorded; None once it is (or it is gone)."""
    day = row.scheduled_on
    wall_time = row.time_of_day.strftime("%H:%M")
    if row.task == "dose":
        for item in MedicationQueries(session, now).occurrences(
            row.care_circle_id, day, day
        ):
            if item["schedule_id"] == str(row.task_id):
                return item["name"] if item["record"] is None else None
        return None
    for item in MeasurementQueries(session, now).occurrences(
        row.care_circle_id, day, day
    ):
        if (
            item["plan_version_id"] == str(row.task_id)
            and item["time_of_day"] == wall_time
        ):
            if item["status"] in ANSWERED:
                return None
            return "سكر الدم" if item["kind"] == "glucose" else "ضغط الدم"
    return None


def snooze_message(row, subject: str, by_name: str | None) -> PushMessage:
    """«حان موعد الجرعة المؤجّلة», then which, for how long and by whom:
    «جرعة فيتامين د تأجّلت 15 دقيقة بواسطة لينا». «بواسطة» fits a woman
    and a man alike."""
    after = minutes_text(row.minutes)
    by = f" بواسطة {by_name}" if by_name else ""
    circle, day = row.care_circle_id, row.scheduled_on
    if row.task == "dose":
        return PushMessage(
            "حان موعد الجرعة المؤجّلة",
            f"جرعة {subject} تأجّلت {after}{by}",
            "dose_snoozed",
            dose_target(circle, row.task_id, day),
        )
    wall_time = row.time_of_day.strftime("%H:%M")
    return PushMessage(
        "حان موعد القياس المؤجّل",
        f"قياس {subject} تأجّل {after}{by}",
        "measurement_snoozed",
        measurement_target(circle, row.task_id, day, wall_time),
    )


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
