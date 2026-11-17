"""The kinds of visit an appointment can be. One list, shared by the
request schema and the table's check constraint; the app shows the same
list, grouped."""

APPOINTMENT_KINDS: tuple[str, ...] = (
    # Seeing the doctor.
    "follow_up", "new_visit", "remote", "emergency",
    # Checks.
    "test", "imaging", "eye_exam", "hearing_test",
    # Treatment and procedures.
    "surgery", "physio", "dialysis", "therapy_session", "dressing",
    # Prevention and routine care.
    "vaccine", "checkup", "dental", "pharmacy",
    # Sessions.
    "mental", "speech",
    # Typed by the person, in other_text.
    "other",
)


def kinds_sql() -> str:
    """The constraint's list: «'follow_up', 'new_visit', …»."""
    return ", ".join(f"'{kind}'" for kind in APPOINTMENT_KINDS)


# What each kind is called, as the app names it («appointments.kinds»), so
# a push says which visit it is about.
KIND_NAMES: dict[str, str] = {
    "follow_up": "مراجعة", "new_visit": "كشف جديد",
    "remote": "استشارة عن بُعد", "emergency": "طوارئ", "test": "تحليل",
    "imaging": "أشعة", "eye_exam": "فحص نظر", "hearing_test": "فحص سمع",
    "surgery": "عملية", "physio": "علاج طبيعي", "dialysis": "غسيل كلى",
    "therapy_session": "جلسة علاج", "dressing": "تغيير ضماد أو إبرة",
    "vaccine": "تطعيم", "checkup": "فحص دوري", "dental": "أسنان",
    "pharmacy": "صرف أدوية", "mental": "جلسة نفسية",
    "speech": "جلسة نطق وتخاطب",
}


def visit_name(kind: str, other_text: str | None) -> str | None:
    """«غسيل كلى»; for «أخرى», what the person typed; None when unknown."""
    if kind == "other":
        return (other_text or "").strip() or None
    return KIND_NAMES.get(kind)
