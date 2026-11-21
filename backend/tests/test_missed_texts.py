"""The words of the missed-task pushes: each person called by name, the
patient told it is theirs, everyone else told whose it is."""

from app.appointments.kinds import APPOINTMENT_KINDS, KIND_NAMES, visit_name
from app.push.missed_texts import (
    appointment_missed_text,
    dose_missed_text,
    measurement_missed_text,
)


def test_a_missed_dose_to_the_patient_and_to_a_carer():
    assert dose_missed_text(
        "فيتامين ب12", name="خالد", own=True, patient="خالد"
    ) == "يا خالد، جرعة فيتامين ب12 فاتت، الأفضل أخذها الآن"
    assert dose_missed_text(
        "فيتامين ب12", name="لينا", own=False, patient="خالد"
    ) == "يا لينا، جرعة فيتامين ب12 لـخالد فاتت، الأفضل أخذها الآن"


def test_a_missed_reading_says_sugar_or_pressure():
    assert measurement_missed_text(
        "glucose", name="نورة", own=True, patient="نورة"
    ) == "يا نورة، قياس السكر فات، الأفضل القياس الآن"
    assert measurement_missed_text(
        "blood_pressure", name="لينا", own=False, patient="نورة"
    ) == "يا لينا، قياس الضغط لـنورة فات، الأفضل القياس الآن"


def test_a_missed_appointment_to_the_patient_and_to_a_carer():
    assert appointment_missed_text(
        name="خالد", own=True, patient="خالد"
    ) == "يا خالد، الموعد فاتك"
    assert appointment_missed_text(
        name="لينا", own=False, patient="خالد"
    ) == "يا لينا، موعد خالد فات"


def test_a_missed_appointment_says_which_visit():
    assert appointment_missed_text(
        name="خالد", own=True, patient="خالد", visit="غسيل كلى"
    ) == "يا خالد، موعد غسيل كلى فاتك"
    assert appointment_missed_text(
        name="لينا", own=False, patient="خالد", visit="غسيل كلى"
    ) == "يا لينا، موعد غسيل كلى لـخالد فات"


def test_a_visit_is_named_as_the_app_names_it():
    assert visit_name("dialysis", None) == "غسيل كلى"
    assert visit_name("other", " علاج بالضوء ") == "علاج بالضوء"
    assert visit_name("other", "  ") is None
    assert set(KIND_NAMES) == set(APPOINTMENT_KINDS) - {"other"}


def test_a_missing_name_is_left_out_never_blank():
    assert dose_missed_text(
        "بنادول", name=None, own=False, patient=" "
    ) == "جرعة بنادول فاتت، الأفضل أخذها الآن"
    assert appointment_missed_text(
        name="", own=False, patient=None
    ) == "الموعد فات"
