import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:equatable/equatable.dart';

/// Summarizes the most recent recorded dose.
class MedicationLastRecord extends Equatable {
  const MedicationLastRecord({
    required this.outcome,
    required this.scheduledOn,
    required this.time,
    this.takenAt,
    this.skipReasonCode,
    this.skipReasonNote,
    this.recordedByAccountId,
    this.recordedByName,
    this.recordedByAvatarCode,
  });

  final DoseOutcome outcome;
  final DateTime scheduledOn;
  final String time;
  final DateTime? takenAt;
  final String? skipReasonCode;
  final String? skipReasonNote;
  final String? recordedByAccountId;
  final String? recordedByName;
  final String? recordedByAvatarCode;

  @override
  List<Object?> get props => [
    outcome,
    scheduledOn,
    time,
    takenAt,
    skipReasonCode,
    skipReasonNote,
    recordedByAccountId,
    recordedByName,
    recordedByAvatarCode,
  ];
}
