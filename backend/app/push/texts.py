"""The Arabic words of the pushes, the app's own: «ال» before a medicine's
name and «لـ» before a visit's; «جرعة فائتة», «قياس فائت» and «موعد فائت»;
what needs attention («يحتاج انتباهك»); and the reminders at a task's time
and before a visit.

Each person is called by their name; everyone but the patient also hears
whose task it is («لـخالد»)."""

from app.models.appointment import visit_name
from app.snoozes.due import clock_text, minutes_text


def with_article(name: str | None) -> str:
    """«البتراترا» for «بتراترا», as the app says a medicine (`withArticle`
    in arabic_names.dart). A name with «ال» already, or not written in
    Arabic letters («Panadol»), stays as it is."""
    value = (name or "").strip()
    if not value or value.startswith("ال"):
        return value
    return f"ال{value}" if _arabic(value[0]) else value


# Visits that read better known («موعد خالد للطوارئ», not «لطوارئ»).
_KNOWN_VISITS = {"طوارئ": "للطوارئ", "أسنان": "للأسنان", "أشعة": "للأشعة"}


def for_visit(visit: str | None) -> str:
    """«لجلسة علاج», «للتطعيم» for a name with «ال» (the «ال» joins «لـ» as
    «لل»), «لـMRI» for one in other letters; empty without a name."""
    value = (visit or "").strip()
    if not value:
        return ""
    if value in _KNOWN_VISITS:
        return _KNOWN_VISITS[value]
    if value.startswith("ال"):
        return f"لل{value[2:]}"
    return f"ل{value}" if _arabic(value[0]) else f"لـ{value}"


def _arabic(letter: str) -> bool:
    """Whether `letter` is one of the Arabic letters, hamza to yeh."""
    return "ء" <= letter <= "ي"


MISSED_DOSE_TITLE = "جرعة فائتة"

MISSED_MEASUREMENT_TITLE = "قياس فائت"

MISSED_APPOINTMENT_TITLE = "موعد فائت"

# What «قياس …» is called for each reading kind.
READING = {"glucose": "السكر", "blood_pressure": "الضغط"}


def dose_missed_text(
    medicine: str, *, name: str | None, own: bool, patient: str | None
) -> str:
    """«يا خالد، جرعة فيتامين ب12 فاتت، الأفضل أخذها الآن» to the patient
    ([own]); «يا لينا، جرعة فيتامين ب12 لـخالد فاتت، الأفضل أخذها الآن» to
    the others."""
    return (
        f"{greeting(name)}جرعة {medicine}{whose(own, patient)} فاتت، "
        "الأفضل أخذها الآن"
    )


def measurement_missed_text(
    kind: str, *, name: str | None, own: bool, patient: str | None
) -> str:
    """«يا خالد، قياس السكر فات، الأفضل القياس الآن» to the patient
    ([own]); «يا لينا، قياس الضغط لـخالد فات، الأفضل القياس الآن» to the
    others."""
    reading = READING.get(kind, "الضغط")
    return (
        f"{greeting(name)}قياس {reading}{whose(own, patient)} فات، "
        "الأفضل القياس الآن"
    )


def appointment_missed_text(
    *, name: str | None, own: bool, patient: str | None,
    visit: str | None = None,
) -> str:
    """«يا خالد، موعد غسيل كلى فاتك» to the patient ([own]); «يا لينا،
    موعد غسيل كلى لـخالد فات» to the others. Without the [visit]'s name:
    «الموعد فاتك» and «موعد خالد فات»."""
    visit = (visit or "").strip()
    if not visit:
        if own:
            return f"{greeting(name)}الموعد فاتك"
        owner = f"موعد {patient}" if patient else "الموعد"
        return f"{greeting(name)}{owner} فات"
    if own:
        return f"{greeting(name)}موعد {visit} فاتك"
    return f"{greeting(name)}موعد {visit}{whose(own, patient)} فات"


def greeting(name: str | None) -> str:
    """«يا لينا، », or nothing without a name."""
    name = (name or "").strip()
    return f"يا {name}، " if name else ""


def whose(own: bool, patient: str | None) -> str:
    """« لـخالد» for everyone but the patient, when the name is known."""
    patient = (patient or "").strip()
    return "" if own or not patient else f" لـ{patient}"


UNUSUAL_READING_TITLE = "قياس غير معتاد"

SKIPPED_DOSE_TITLE = "جرعة تم تخطيها"

CANCELLED_APPOINTMENT_TITLE = "موعد تم إلغاؤه"


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


DOSE_REMINDER_TITLE = "حان موعد الدواء"

MEASUREMENT_REMINDER_TITLE = "حان وقت القياس"

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
    return DOSE_REMINDER_TITLE, f"{greeting(name)}{body}"


def measurement_words(
    kind: str, name: str | None, patient: str | None
) -> tuple[str, str]:
    """«ياسر، حان وقت القياس» over «سكر الدم»; «سكر الدم لـنورة» to
    someone caring for Nora (`patient`)."""
    name = (name or "").strip()
    title = MEASUREMENT_REMINDER_TITLE
    if name:
        title = f"{name}، {title}"
    reading = READINGS.get(kind, READINGS["blood_pressure"])
    return title, f"{reading}{for_patient(patient)}"


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
