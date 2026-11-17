import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/domain/medical_options.dart';

/// Turning what the chips show into what the API takes.
extension MedicalFormAnswers on MedicalForm {
  /// The answers to save. A part with nothing chosen is null, which clears it
  /// back to "unknown" on the server.
  MedicalProfileDraft toProfile() {
    return MedicalProfileDraft(
      bloodType: bloodType,
      conditions: _conditionsAnswer(),
      allergies: _allergiesAnswer(),
    );
  }

  ConditionsDraft? _conditionsAnswer() {
    if (conditions.isEmpty) return null;
    if (conditions.contains(MedicalOptions.none)) {
      return const ConditionsDraft.none();
    }
    final List<String> codes = _inOrder(conditions, <String>[
      ...MedicalOptions.conditions,
      MedicalOptions.other,
    ]);
    return ConditionsDraft.listed(
      codes: codes,
      other: codes.contains(MedicalOptions.other)
          ? conditionOther.trim()
          : null,
    );
  }

  AllergiesDraft? _allergiesAnswer() {
    if (noAllergies) return const AllergiesDraft.none();
    if (medication.isEmpty && food.isEmpty) return null;
    final List<String> medicines = _inOrder(medication, <String>[
      ...MedicalOptions.medications,
      MedicalOptions.other,
    ]);
    final List<String> foods = _inOrder(food, <String>[
      ...MedicalOptions.foods,
      MedicalOptions.other,
    ]);
    return AllergiesDraft.listed(
      medication: medicines,
      otherMedication: medicines.contains(MedicalOptions.other)
          ? medicationOther.trim()
          : null,
      food: foods,
      otherFood: foods.contains(MedicalOptions.other) ? foodOther.trim() : null,
    );
  }

  /// The chosen codes in the order of the design.
  List<String> _inOrder(Set<String> chosen, List<String> order) {
    return <String>[
      for (final String code in order)
        if (chosen.contains(code)) code,
    ];
  }
}
