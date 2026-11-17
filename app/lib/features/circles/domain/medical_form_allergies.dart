import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/domain/medical_options.dart';
import 'package:app/features/circles/domain/medical_form_copy.dart';

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
