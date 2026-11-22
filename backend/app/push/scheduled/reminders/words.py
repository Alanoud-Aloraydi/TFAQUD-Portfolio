"""The words of the reminders at a dose's and a reading's time: the app's
own (ar.json "reminders", dose_reminder_texts.dart).

A person is called by their name when they have one, and someone caring
for the patient also hears whose task it is («لـنورة»). «لا ننسى» (we)
fits a woman and a man alike, as «لا تنسى» and «لا تنسي» would not."""

from app.push.arabic_words import with_article
from app.push.missed_texts import greeting

DOSE_TITLE = "حان موعد الدواء"
MEASUREMENT_TITLE = "حان وقت القياس"

# What each reading is called («measurements.glucose», «measurements.bp»).
READINGS = {"glucose": "سكر الدم", "blood_pressure": "ضغط الدم"}


def for_patient(patient: str | None) -> str:
    """« لـنورة» for someone caring for Nora; nothing for the patient, or
    without the name."""
    patient = (patient or "").strip()
    return f" لـ{patient}" if patient else ""


def dose_words(
    medicine: str, name: str | None, patient: str | None
) -> tuple[str, str]:
    """«حان موعد الدواء» over «يا ياسر، لا ننسى الميلبون»; «… لـنورة» to
    someone caring for Nora (`patient`)."""
    body = f"لا ننسى {with_article(medicine)}{for_patient(patient)}"
    return DOSE_TITLE, f"{greeting(name)}{body}"


def measurement_words(
    kind: str, name: str | None, patient: str | None
) -> tuple[str, str]:
    """«ياسر، حان وقت القياس» over «سكر الدم»; «سكر الدم لـنورة» to
    someone caring for Nora (`patient`)."""
    name = (name or "").strip()
    title = f"{name}، {MEASUREMENT_TITLE}" if name else MEASUREMENT_TITLE
    reading = READINGS.get(kind, READINGS["blood_pressure"])
    return title, f"{reading}{for_patient(patient)}"
