"""The words of «جرعة فائتة», «قياس فائت» and «موعد فائت».

Each person is called by their name; everyone but the patient also hears
whose task it is («لـخالد»). The words fit a woman and a man alike: no
verb is spoken to one of them («الأفضل أخذها الحين», never «سارع» or
«ليسارع»). A name that is missing is left out, never written as a blank.
"""

DOSE_TITLE = "جرعة فائتة"
MEASUREMENT_TITLE = "قياس فائت"
APPOINTMENT_TITLE = "موعد فائت"

# What «قياس …» is called for each reading kind.
_READING = {"glucose": "السكر", "blood_pressure": "الضغط"}


def dose_missed_text(
    medicine: str, *, name: str | None, own: bool, patient: str | None
) -> str:
    """«يا خالد، جرعة فيتامين ب12 فاتت، الأفضل أخذها الحين» to the patient
    ([own]); «يا لينا، جرعة فيتامين ب12 لـخالد فاتت، الأفضل أخذها الحين» to
    the others."""
    return (
        f"{_greeting(name)}جرعة {medicine}{_whose(own, patient)} فاتت، "
        "الأفضل أخذها الحين"
    )


def measurement_missed_text(
    kind: str, *, name: str | None, own: bool, patient: str | None
) -> str:
    """«يا خالد، قياس السكر فات، الأفضل القياس الحين» to the patient
    ([own]); «يا لينا، قياس الضغط لـخالد فات، الأفضل القياس الحين» to the
    others."""
    reading = _READING.get(kind, "الضغط")
    return (
        f"{_greeting(name)}قياس {reading}{_whose(own, patient)} فات، "
        "الأفضل القياس الحين"
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
            return f"{_greeting(name)}الموعد فاتك"
        whose = f"موعد {patient}" if patient else "الموعد"
        return f"{_greeting(name)}{whose} فات"
    if own:
        return f"{_greeting(name)}موعد {visit} فاتك"
    return f"{_greeting(name)}موعد {visit}{_whose(own, patient)} فات"


def _greeting(name: str | None) -> str:
    """«يا لينا، », or nothing without a name."""
    name = (name or "").strip()
    return f"يا {name}، " if name else ""


def _whose(own: bool, patient: str | None) -> str:
    """« لـخالد» for everyone but the patient, when the name is known."""
    patient = (patient or "").strip()
    return "" if own or not patient else f" لـ{patient}"
