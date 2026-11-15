"""What a put-off task's reminder says, and which task it is about."""

from datetime import datetime

from app.measurements.queries import MeasurementQueries
from app.medications.queries import MedicationQueries
from app.push.sender import PushMessage
from app.push.targets import dose_target, measurement_target
from app.snoozes.arabic_texts import minutes_text

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
    """«حان موعد الجرعة المؤجّلة» and who put it off, for how long."""
    after = minutes_text(row.minutes)
    by = f" من {by_name}" if by_name else ""
    circle, day = row.care_circle_id, row.scheduled_on
    if row.task == "dose":
        return PushMessage(
            "حان موعد الجرعة المؤجّلة",
            f"جرعة {subject} تأجّلت {after}{by}، وحان وقتها. "
            "تقدر تسجّلها من تفقّد.",
            "dose_snoozed",
            dose_target(circle, row.task_id, day),
        )
    wall_time = row.time_of_day.strftime("%H:%M")
    return PushMessage(
        "حان موعد القياس المؤجّل",
        f"قياس {subject} تأجّل {after}{by}، وحان وقته. "
        "تقدر تسجّله من تفقّد.",
        "measurement_snoozed",
        measurement_target(circle, row.task_id, day, wall_time),
    )
