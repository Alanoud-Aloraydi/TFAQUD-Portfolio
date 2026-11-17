import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/domain/medical_options.dart';

/// Reads saved answers. A part that was never answered gives no chosen
/// chip.
MedicalForm medicalFormOf(MedicalProfileDraft profile) {
  final ConditionsDraft? conditions = profile.conditions;
  final AllergiesDraft? allergies = profile.allergies;
  final Set<String> chosenConditions = conditions == null
      ? <String>{}
      : conditions.answer == ListAnswer.none
      ? <String>{MedicalOptions.none}
      : conditions.codes.toSet();
  return MedicalForm(
    bloodType: profile.bloodType,
    conditions: chosenConditions,
    conditionOther: conditions?.other ?? '',
    noAllergies: allergies?.answer == ListAnswer.none,
    medication: allergies?.medication.toSet() ?? const <String>{},
    medicationOther: allergies?.otherMedication ?? '',
    food: allergies?.food.toSet() ?? const <String>{},
    foodOther: allergies?.otherFood ?? '',
  );
}
