import 'package:app/features/circles/domain/medical_form.dart';

/// The same answers with some of them replaced. The blood type is
/// changed by its own tap only, so it is always carried over here.
extension MedicalFormCopy on MedicalForm {
  MedicalForm copy({
    Set<String>? conditions,
    String? conditionOther,
    bool? noAllergies,
    Set<String>? medication,
    String? medicationOther,
    Set<String>? food,
    String? foodOther,
  }) {
    return MedicalForm(
      bloodType: bloodType,
      conditions: conditions ?? this.conditions,
      conditionOther: conditionOther ?? this.conditionOther,
      noAllergies: noAllergies ?? this.noAllergies,
      medication: medication ?? this.medication,
      medicationOther: medicationOther ?? this.medicationOther,
      food: food ?? this.food,
      foodOther: foodOther ?? this.foodOther,
    );
  }
}
