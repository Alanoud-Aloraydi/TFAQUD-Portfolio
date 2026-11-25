import 'package:app/features/circles/domain/entities/medical_options.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:equatable/equatable.dart';

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
