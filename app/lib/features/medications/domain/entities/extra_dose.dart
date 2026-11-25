import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:equatable/equatable.dart';

/// A dose of «سجّل جرعة الآن»: taken when the person chose, always on top
/// of the medicine's scheduled doses, never one of them.
class ExtraDose extends Equatable {
  const ExtraDose({
    required this.id,
    required this.planId,
    required this.takenAt,
    required this.doseValue,
    required this.doseUnit,
    this.recordedByAccountId,
    this.recordedByName,
    this.recordedByAvatarCode,
  });

  final String id;
  final String planId;

  /// A real moment, shown on the patient's clock.
  final DateTime takenAt;
  final double doseValue;
  final DoseUnit doseUnit;

  /// Who recorded it, with their photo or avatar in «سجل الجرعات»: null
  /// once their account was deleted.
  final String? recordedByAccountId;
  final String? recordedByName;
  final String? recordedByAvatarCode;

  @override
  List<Object?> get props => [
    id,
    planId,
    takenAt,
    doseValue,
    doseUnit,
    recordedByAccountId,
    recordedByName,
    recordedByAvatarCode,
  ];
}

/// An extra dose before it is sent.
class ExtraDoseDraft extends Equatable {
  const ExtraDoseDraft({
    required this.planId,
    required this.takenAt,
    required this.doseValue,
    required this.doseUnit,
  });

  final String planId;
  final DateTime takenAt;
  final double doseValue;
  final DoseUnit doseUnit;

  @override
  List<Object?> get props => [planId, takenAt, doseValue, doseUnit];
}
