"""The words of an appointment's reminders, the app's own: «يا ياسر، لا
ننسى موعدك غدًا» over «مراجعة، عيادة السكري، الساعة 4:30 م، مستشفى الملك
فهد»; «… موعد نورة …» to someone caring for Nora."""

from app.appointments.kinds import visit_name
from app.push.missed_texts import greeting
from app.snoozes.arabic_texts import clock_text, minutes_text

TOMORROW = "غدًا"
TODAY = "اليوم"
# A visit of the kind «أخرى» with nothing typed for it.
OTHER = "أخرى"


def after(minutes: int) -> str:
    """«بعد ساعة», «بعد 45 دقيقة», «بعد ساعة و5 دقائق»."""
    return f"بعد {minutes_text(minutes)}"


def visit_title(when: str, name: str | None, patient: str | None) -> str:
    """«يا ياسر، لا ننسى موعدك غدًا»; «… موعد نورة بعد ساعة» to someone
    caring for Nora (`patient`)."""
    patient = (patient or "").strip()
    whose = f"موعد {patient}" if patient else "موعدك"
    return f"{greeting(name)}لا ننسى {whose} {when}"


def visit_body(visit) -> str:
    """«مراجعة، عيادة السكري، الساعة 4:30 م»: the kind, the clinic when one
    was typed, the time, and the place after it when one was typed."""
    kind = visit_name(visit.kind, visit.other_text) or OTHER
    clinic = (visit.specialty or "").strip()
    named = f"{kind}، {clinic}" if clinic else kind
    text = f"{named}، الساعة {clock_text(visit.time_of_day)}"
    place = (visit.place or "").strip()
    return f"{text}، {place}" if place else text


def visit_words(
    when: str, body: str, name: str | None, patient: str | None
) -> tuple[str, str]:
    """The title for this person, over the visit's own line."""
    return visit_title(when, name, patient), body
