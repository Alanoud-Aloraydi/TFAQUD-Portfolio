import 'package:app/features/circles/domain/entities/medical_options.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:equatable/equatable.dart';

export 'package:app/features/circles/domain/entities/medical_form_allergies.dart';
export 'package:app/features/circles/domain/entities/medical_form_answers.dart';

/// What the edit page of the medical file keeps while the user chooses: the
/// blood type, the chronic conditions and the allergies, in the form the chips
/// show them. [toProfile] turns it into the answers the API takes, and
/// [MedicalForm.fromProfile] does the opposite for the saved answers.
///
/// The rules: "none" stands alone, a second tap on a choice clears it, and
/// the typed text of "other" is kept only while "other" is chosen. A circle
/// is created without these answers; they are filled here afterwards.
class MedicalForm extends Equatable {
  const MedicalForm({
    this.bloodType,
    this.conditions = const <String>{},
    this.conditionOther = '',
    this.noAllergies = false,
    this.medication = const <String>{},
    this.medicationOther = '',
    this.food = const <String>{},
    this.foodOther = '',
  });

  /// Reads saved answers. A part that was never answered gives no chosen
  /// chip.
  factory MedicalForm.fromProfile(MedicalProfileDraft profile) =>
      medicalFormOf(profile);

  final String? bloodType;

  /// Codes of the chosen conditions, including "none" and "other".
  final Set<String> conditions;
  final String conditionOther;

  final bool noAllergies;
  final Set<String> medication;
  final String medicationOther;
  final Set<String> food;
  final String foodOther;

  /// "Other" needs its text, here and in the two lists of allergies.
  bool get conditionsValid =>
      !conditions.contains(MedicalOptions.other) ||
      conditionOther.trim().isNotEmpty;

  bool get allergiesValid =>
      (!medication.contains(MedicalOptions.other) ||
          medicationOther.trim().isNotEmpty) &&
      (!food.contains(MedicalOptions.other) || foodOther.trim().isNotEmpty);

  @override
  List<Object?> get props => [
    bloodType,
    conditions,
    conditionOther,
    noAllergies,
    medication,
    medicationOther,
    food,
    foodOther,
  ];
}

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
