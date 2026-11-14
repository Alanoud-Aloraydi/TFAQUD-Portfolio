"""The words of «جرعة فائتة», «قياس فائت» and «موعد فائت».

Each person is called by their name. The patient hears that the task is
theirs («سارع بأخذها»); everyone else in the circle also hears whose it
is, and that the patient should hurry («لـخالد … ليسارع بأخذها»). A name
that is missing is left out, never written as a blank.
"""

DOSE_TITLE = "جرعة فائتة"
MEASUREMENT_TITLE = "قياس فائت"
APPOINTMENT_TITLE = "موعد فائت"

# What «قياس …» is called for each reading kind.
_READING = {"glucose": "السكر", "blood_pressure": "الضغط"}


def dose_missed_text(
    medicine: str, *, name: str | None, own: bool, patient: str | None
) -> str:
    """«يا خالد، جرعة فيتامين ب12 فاتت، سارع بأخذها» to the patient ([own]);
    «يا لينا، جرعة فيتامين ب12 لـخالد فاتت، ليسارع بأخذها» to the others."""
    hurry = "سارع" if own else "ليسارع"
    return (
        f"{_greeting(name)}جرعة {medicine}{_whose(own, patient)} فاتت، "
        f"{hurry} بأخذها"
    )


def measurement_missed_text(
    kind: str, *, name: str | None, own: bool, patient: str | None
) -> str:
    """«يا خالد، قياس السكر فات، سارع بالقياس» to the patient ([own]);
    «يا لينا، قياس الضغط لـخالد فات، ليسارع بالقياس» to the others."""
    hurry = "سارع" if own else "ليسارع"
    reading = _READING.get(kind, "الضغط")
    return (
        f"{_greeting(name)}قياس {reading}{_whose(own, patient)} فات، "
        f"{hurry} بالقياس"
    )


def appointment_missed_text(
    *, name: str | None, own: bool, patient: str | None
) -> str:
    """«يا خالد، الموعد فاتك» to the patient ([own]); «يا لينا، موعد خالد
    فات» to the others."""
    if own:
        return f"{_greeting(name)}الموعد فاتك"
    whose = f"موعد {patient}" if patient else "الموعد"
    return f"{_greeting(name)}{whose} فات"


def _greeting(name: str | None) -> str:
    """«يا لينا، », or nothing without a name."""
    name = (name or "").strip()
    return f"يا {name}، " if name else ""


def _whose(own: bool, patient: str | None) -> str:
    """« لـخالد» for everyone but the patient, when the name is known."""
    patient = (patient or "").strip()
    return "" if own or not patient else f" لـ{patient}"
