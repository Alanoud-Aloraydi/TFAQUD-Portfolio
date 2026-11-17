import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/domain/medical_form_copy.dart';

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
