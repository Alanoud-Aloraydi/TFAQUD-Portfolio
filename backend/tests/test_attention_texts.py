"""The words of «يحتاج انتباهك» pushes: a reading outside its range, a
skipped dose with its reason, a cancelled visit."""

import pytest

from app.push.texts import for_visit, with_article
from app.push.texts import (
    appointment_cancelled_text,
    dose_skipped_text,
    reading_unusual_text,
)


def test_a_reading_names_whose_it_is_to_the_others_only():
    assert reading_unusual_text(
        "glucose", name="لينا", own=False, patient="خالد"
    ) == "يا لينا، قياس السكر لـخالد يحتاج انتباهك!"
    assert reading_unusual_text(
        "blood_pressure", name="خالد", own=True, patient="خالد"
    ) == "يا خالد، قياس الضغط يحتاج انتباهك!"


@pytest.mark.parametrize(
    ("reason", "note", "words"),
    [
        ("forgotten", None, " بسبب نسيان خالد لأخذه"),
        ("unavailable", None, " بسبب عدم توفر الدواء لـخالد"),
        ("side_effects", None, " بسبب ظهور أعراض جانبية"),
        ("patient_refused", None, " بسبب عدم رغبة خالد في أخذه"),
        ("other", "السفر.", " بسبب السفر"),
        ("other", "بسبب السفر", " بسبب السفر"),
        ("other", "لأنه مسافر", " لأنه مسافر"),
        ("other", "  ", ""),
        (None, None, ""),
    ],
)
def test_a_skipped_dose_says_why_in_proper_arabic(reason, note, words):
    assert dose_skipped_text(
        "بتراترا", reason, note, name="لينا", own=False, patient="خالد"
    ) == f"يا لينا، دواء خالد البتراترا تم تخطيه{words}"


def test_the_patient_hears_of_their_own_dose():
    assert dose_skipped_text(
        "Panadol", "forgotten", None, name="خالد", own=True, patient="خالد"
    ) == "يا خالد، دواؤك Panadol تم تخطيه بسبب نسيانك لأخذه"
    assert dose_skipped_text(
        "البنادول", "patient_refused", None,
        name="خالد", own=True, patient="خالد",
    ) == "يا خالد، دواؤك البنادول تم تخطيه بسبب عدم رغبتك في أخذه"


def test_missing_names_are_left_out():
    assert dose_skipped_text(
        None, "forgotten", None, name=None, own=False, patient=None
    ) == "الدواء تم تخطيه بسبب نسيان أخذه"
    assert appointment_cancelled_text(
        None, name="لينا", own=False, patient="خالد"
    ) == "يا لينا، موعد خالد تم إلغاؤه"


def test_a_cancelled_visit_says_which_with_its_lam():
    assert appointment_cancelled_text(
        "جلسة علاج", name="لينا", own=False, patient="خالد"
    ) == "يا لينا، موعد خالد لجلسة علاج تم إلغاؤه"
    assert appointment_cancelled_text(
        "غسيل كلى", name="خالد", own=True, patient="خالد"
    ) == "يا خالد، موعدك لغسيل كلى تم إلغاؤه"


@pytest.mark.parametrize(
    ("visit", "words"),
    [
        ("مراجعة", "لمراجعة"),
        ("استشارة عن بُعد", "لاستشارة عن بُعد"),
        ("طوارئ", "للطوارئ"),
        ("أسنان", "للأسنان"),
        ("العيادة الجلدية", "للعيادة الجلدية"),
        ("MRI", "لـMRI"),
        ("", ""),
    ],
)
def test_lam_joins_the_visit(visit, words):
    assert for_visit(visit) == words


@pytest.mark.parametrize(
    ("name", "words"),
    [
        ("بتراترا", "البتراترا"),
        ("الأنسولين", "الأنسولين"),
        ("Panadol", "Panadol"),
        ("  ", ""),
    ],
)
def test_a_medicine_takes_al_as_the_app_says_it(name, words):
    assert with_article(name) == words
