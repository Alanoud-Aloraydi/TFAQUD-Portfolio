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
