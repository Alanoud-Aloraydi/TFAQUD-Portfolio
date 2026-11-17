"""The words of the messages about what needs attention, as «يحتاج
انتباهك» on «اليوم» shows it: a reading outside its normal range, a dose
skipped, a visit cancelled.

The same voice as missed_texts.py: each person by their name, the patient
told of their own («دواؤك»), the others of whose («دواء خالد»), and no word
that fits only a man or only a woman. A missing name is left out.
"""

from app.push.arabic_words import for_visit, with_article
from app.push.missed_texts import READING, greeting, whose

READING_TITLE = "قياس غير معتاد"
DOSE_TITLE = "جرعة تم تخطيها"
APPOINTMENT_TITLE = "موعد تم إلغاؤه"


def reading_unusual_text(
    kind: str, *, name: str | None, own: bool, patient: str | None
) -> str:
    """«يا لينا، قياس السكر لـخالد يحتاج انتباهك!»; to the patient: «يا
    خالد، قياس الضغط يحتاج انتباهك!»."""
    reading = READING.get(kind, "الضغط")
    return (
        f"{greeting(name)}قياس {reading}{whose(own, patient)} "
        "يحتاج انتباهك!"
    )


def dose_skipped_text(
    medicine: str | None, reason: str | None, note: str | None, *,
    name: str | None, own: bool, patient: str | None,
) -> str:
    """«يا لينا، دواء خالد البتراترا تم تخطيه بسبب ظهور أعراض جانبية»; to
    the patient: «يا خالد، دواؤك البتراترا تم تخطيه …». Without a reason,
    nothing after «تخطيه»."""
    patient = (patient or "").strip()
    drug = with_article(medicine)
    owner = "دواؤك" if own else f"دواء {patient}" if patient else "دواء"
    subject = f"{owner} {drug}" if drug else (
        "الدواء" if owner == "دواء" else owner
    )
    because = skip_reason_words(reason, note, own=own, patient=patient)
    return f"{greeting(name)}{subject} تم تخطيه{because}"


def skip_reason_words(
    reason: str | None, note: str | None, *, own: bool, patient: str
) -> str:
    """« بسبب نسيان خالد لأخذه» and the like, after «تم تخطيه»; « بسبب» and
    what was typed for «سبب آخر» (as it is when it starts with «بسبب» or
    «لأن»); nothing without a reason. «لأخذه»: the medicine («الدواء»)."""
    if reason == "forgotten":
        who = "نسيانك" if own else f"نسيان {patient}" if patient else ""
        return f" بسبب {who} لأخذه" if who else " بسبب نسيان أخذه"
    if reason == "unavailable":
        to = " لك" if own else f" لـ{patient}" if patient else ""
        return f" بسبب عدم توفر الدواء{to}"
    if reason == "side_effects":
        return " بسبب ظهور أعراض جانبية"
    if reason == "patient_refused":
        who = "رغبتك" if own else f"رغبة {patient}" if patient else "الرغبة"
        return f" بسبب عدم {who} في أخذه"
    if reason == "other":
        typed = (note or "").strip().rstrip(".،!")
        if not typed:
            return ""
        if typed.startswith(("بسبب", "لأن", "لان")):
            return f" {typed}"
        return f" بسبب {typed}"
    return ""


def appointment_cancelled_text(
    visit: str | None, *, name: str | None, own: bool, patient: str | None
) -> str:
    """«يا لينا، موعد خالد لجلسة علاج تم إلغاؤه»; to the patient: «يا خالد،
    موعدك لجلسة علاج تم إلغاؤه». Without the visit's name: «موعد خالد تم
    إلغاؤه»."""
    patient = (patient or "").strip()
    owner = "موعدك" if own else f"موعد {patient}" if patient else "الموعد"
    which = for_visit(visit)
    return f"{greeting(name)}{owner}{' ' + which if which else ''} تم إلغاؤه"
