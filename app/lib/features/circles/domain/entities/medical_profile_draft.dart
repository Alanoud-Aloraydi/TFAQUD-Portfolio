import 'package:equatable/equatable.dart';

/// Whether a list (conditions or allergies) was answered with "none" or with
/// items. A list that was not answered is left out of the profile instead.
enum ListAnswer { none, listed }

/// The chronic conditions the user chose.
class ConditionsDraft extends Equatable {
  const ConditionsDraft.none()
    : answer = ListAnswer.none,
      codes = const <String>[],
      other = null;

  const ConditionsDraft.listed({required this.codes, this.other})
    : answer = ListAnswer.listed;

  final ListAnswer answer;

  /// Codes of the chosen conditions. Empty for [ListAnswer.none].
  final List<String> codes;

  /// The typed text of the "other" condition, when "other" is in [codes].
  final String? other;

  @override
  List<Object?> get props => [answer, codes, other];
}

/// The allergies the user chose.
class AllergiesDraft extends Equatable {
  const AllergiesDraft.none()
    : answer = ListAnswer.none,
      medication = const <String>[],
      otherMedication = null,
      food = const <String>[],
      otherFood = null;

  const AllergiesDraft.listed({
    this.medication = const <String>[],
    this.otherMedication,
    this.food = const <String>[],
    this.otherFood,
  }) : answer = ListAnswer.listed;

  final ListAnswer answer;
  final List<String> medication;
  final String? otherMedication;
  final List<String> food;
  final String? otherFood;

  @override
  List<Object?> get props => [
    answer,
    medication,
    otherMedication,
    food,
    otherFood,
  ];
}

/// The health answers given while a circle is created. A part that the user
/// did not answer is null, and the API then keeps it as "unknown".
class MedicalProfileDraft extends Equatable {
  const MedicalProfileDraft({this.bloodType, this.conditions, this.allergies});

  final String? bloodType;
  final ConditionsDraft? conditions;
  final AllergiesDraft? allergies;

  bool get isEmpty =>
      bloodType == null && conditions == null && allergies == null;

  @override
  List<Object?> get props => [bloodType, conditions, allergies];
}
