import 'package:app/features/circles/domain/entities/medical_form.dart';
import 'package:app/features/circles/domain/entities/medical_options.dart';

/// Taps on the allergies: none at all, the medicines, the foods.
extension MedicalFormAllergies on MedicalForm {
  /// "No allergies" stands alone: it clears the lists, and any item clears it.
  MedicalForm toggleNoAllergies() {
    if (noAllergies) return copy(noAllergies: false);
    return copy(
      noAllergies: true,
      medication: const <String>{},
      medicationOther: '',
      food: const <String>{},
      foodOther: '',
    );
  }

  MedicalForm toggleMedication(String code) {
    final Set<String> next = <String>{...medication};
    if (!next.add(code)) next.remove(code);
    return copy(
      medication: next,
      medicationOther: next.contains(MedicalOptions.other)
          ? medicationOther
          : '',
      noAllergies: false,
    );
  }

  MedicalForm toggleFood(String code) {
    final Set<String> next = <String>{...food};
    if (!next.add(code)) next.remove(code);
    return copy(
      food: next,
      foodOther: next.contains(MedicalOptions.other) ? foodOther : '',
      noAllergies: false,
    );
  }

  MedicalForm withMedicationOther(String text) => copy(medicationOther: text);

  MedicalForm withFoodOther(String text) => copy(foodOther: text);
}

/// Taps on the blood type and the chronic conditions.
extension MedicalFormConditions on MedicalForm {
  /// Picks a blood type; a second tap on the same one clears it.
  MedicalForm chooseBloodType(String code) {
    return MedicalForm(
      bloodType: bloodType == code ? null : code,
      conditions: conditions,
      conditionOther: conditionOther,
      noAllergies: noAllergies,
      medication: medication,
      medicationOther: medicationOther,
      food: food,
      foodOther: foodOther,
    );
  }

  /// "None" stands alone: it clears the other choices, and any other choice
  /// clears it.
  MedicalForm toggleCondition(String code) {
    final Set<String> next = <String>{...conditions};
    if (code == MedicalOptions.none) {
      if (!next.remove(code)) {
        next
          ..clear()
          ..add(code);
      }
    } else {
      next.remove(MedicalOptions.none);
      if (!next.add(code)) next.remove(code);
    }
    return copy(
      conditions: next,
      conditionOther: next.contains(MedicalOptions.other) ? conditionOther : '',
    );
  }

  MedicalForm withConditionOther(String text) => copy(conditionOther: text);
}
