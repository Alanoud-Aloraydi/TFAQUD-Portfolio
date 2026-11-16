export 'package:app/features/circles/domain/entities/allergies_draft.dart';
export 'package:app/features/circles/domain/entities/conditions_draft.dart';
export 'package:app/features/circles/domain/entities/list_answer.dart';
import 'package:app/features/circles/domain/entities/allergies_draft.dart';
import 'package:app/features/circles/domain/entities/conditions_draft.dart';
import 'package:equatable/equatable.dart';

/// The health answers of a patient's medical file. A part that was not
/// answered is null, which the API keeps as "unknown".
class MedicalProfileDraft extends Equatable {
  const MedicalProfileDraft({this.bloodType, this.conditions, this.allergies});

  final String? bloodType;
  final ConditionsDraft? conditions;
  final AllergiesDraft? allergies;

  @override
  List<Object?> get props => [bloodType, conditions, allergies];
}
