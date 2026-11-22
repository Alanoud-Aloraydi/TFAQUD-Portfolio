"""The words, payloads and moments of the reminders the server sends at a
task's time: the same as the app's own reminders (ar.json "reminders",
reminder_payloads.dart, reminder_moments.dart)."""

from dataclasses import dataclass
from datetime import date, datetime, time, timezone
from uuid import UUID
from zoneinfo import ZoneInfo

from app.push.scheduled.reminders.moments import visit_moments
from app.push.scheduled.reminders.payloads import (
    appointment_payload,
    dose_payload,
    measurement_payload,
)
from app.push.scheduled.reminders.visit_words import (
    after,
    visit_body,
    visit_title,
)
from app.push.scheduled.reminders.words import dose_words, measurement_words

CIRCLE = UUID("11111111-1111-1111-1111-111111111111")
RIYADH = ZoneInfo("Asia/Riyadh")


def test_a_dose_calls_each_person_by_name_and_says_whose_it_is():
    assert dose_words("ميلبون", "ياسر", None) == (
        "حان موعد الدواء", "يا ياسر، لا ننسى الميلبون"
    )
    assert dose_words("ميلبون", "ياسر", "نورة")[1] == (
        "يا ياسر، لا ننسى الميلبون لـنورة"
    )
    # Without a name, and a name not in Arabic letters, as the app says.
    assert dose_words("Panadol", None, None)[1] == "لا ننسى Panadol"
    assert dose_words("البنادول", " ", "نورة")[1] == (
        "لا ننسى البنادول لـنورة"
    )


def test_a_reading_names_the_person_in_its_title():
    assert measurement_words("glucose", "ياسر", None) == (
        "ياسر، حان وقت القياس", "سكر الدم"
    )
    assert measurement_words("blood_pressure", None, "نورة") == (
        "حان وقت القياس", "ضغط الدم لـنورة"
    )


def test_a_visit_says_when_and_whose():
    assert visit_title("غدًا", "ياسر", None) == "يا ياسر، لا ننسى موعدك غدًا"
    assert visit_title(after(60), None, "نورة") == (
        "لا ننسى موعد نورة بعد ساعة"
    )
    assert after(90) == "بعد ساعة و30 دقيقة"
    assert after(45) == "بعد 45 دقيقة"
    assert after(120) == "بعد ساعتين"


@dataclass
class Visit:
    kind: str = "follow_up"
    other_text: str | None = None
    specialty: str | None = "عيادة السكري"
    place: str | None = None
    scheduled_on: date = date(2026, 10, 29)
    time_of_day: time = time(16, 30)
    reminder_lead_minutes: int = 60
    updated_at: datetime = datetime(2026, 10, 27, 9, tzinfo=timezone.utc)


def test_a_visit_line_has_its_kind_clinic_time_and_place():
    assert visit_body(Visit()) == "مراجعة، عيادة السكري، الساعة 4:30 م"
    assert visit_body(Visit(place="مستشفى الملك فهد", specialty=None)) == (
        "مراجعة، الساعة 4:30 م، مستشفى الملك فهد"
    )
    assert visit_body(
        Visit(kind="other", other_text=None, specialty=None)
    ) == "أخرى، الساعة 4:30 م"


def test_a_visit_saved_early_reminds_a_day_before_and_at_its_lead():
    # 16:30 in Riyadh is 13:30 UTC.
    assert visit_moments(Visit(), RIYADH) == [
        ("day_before", datetime(2026, 10, 28, 13, 30, tzinfo=timezone.utc)),
        ("soon", datetime(2026, 10, 29, 12, 30, tzinfo=timezone.utc)),
    ]


def test_a_visit_saved_after_its_day_before_moment_is_said_at_once():
    saved = datetime(2026, 10, 28, 20, tzinfo=timezone.utc)
    assert visit_moments(Visit(updated_at=saved), RIYADH) == [
        ("soon", datetime(2026, 10, 29, 12, 30, tzinfo=timezone.utc)),
        ("today", datetime(2026, 10, 28, 20, 0, 30, tzinfo=timezone.utc)),
    ]


def test_a_near_reminder_within_ten_minutes_says_it_alone():
    saved = datetime(2026, 10, 29, 12, 25, tzinfo=timezone.utc)
    assert visit_moments(Visit(updated_at=saved), RIYADH) == [
        ("soon", datetime(2026, 10, 29, 12, 30, tzinfo=timezone.utc)),
    ]


def test_the_payloads_are_the_phone_reminders_own():
    dose = dose_payload(
        CIRCLE, "s-1", date(2026, 3, 5), "Metformin", "حان", "لا ننسى"
    )
    assert dose.split("\x1f") == [
        f"dose:{CIRCLE}", "حان", "لا ننسى", f"{CIRCLE}|s-1|2026-3-5",
        "Metformin",
    ]
    reading = measurement_payload(
        CIRCLE, "v-1", "09:00", date(2026, 3, 5), "blood_pressure", "t", "b"
    )
    assert reading.split("\x1f") == [
        f"measurement:{CIRCLE}", "t", "b",
        f"{CIRCLE}|measurement|v-1|09:00|2026-3-5", "bp",
    ]
    assert appointment_payload(CIRCLE, "a-1", "t", "b") == (
        f"appointment:{CIRCLE}@a-1"
    )
