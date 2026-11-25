import 'package:app/app/services/reminders/shared_snooze.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:equatable/equatable.dart';

/// The server's record of one dose explicitly taken or skipped; a dose
/// with no record has not been answered yet.
class DoseRecord extends Equatable {
  const DoseRecord({
    required this.id,
    required this.outcome,
    required this.recordedAt,
    this.takenAt,
    this.skipReasonCode,
    this.skipReasonNote,
    this.recordedByAccountId,
    this.recordedByName,
    this.recordedByAvatarCode,
  });

  final String id;
  final DoseOutcome outcome;

  /// The real moment it was taken; null when skipped.
  final DateTime? takenAt;
  final String? skipReasonCode;
  final String? skipReasonNote;

  /// When the server saved it.
  final DateTime recordedAt;

  /// Who recorded it: null for a dose from before this was tracked.
  final String? recordedByAccountId;
  final String? recordedByName;
  final String? recordedByAvatarCode;

  @override
  List<Object?> get props => [
    id,
    outcome,
    takenAt,
    skipReasonCode,
    skipReasonNote,
    recordedAt,
    recordedByAccountId,
    recordedByName,
    recordedByAvatarCode,
  ];
}

/// The same dose with one thing answered: a dose is immutable, so each
/// answer is a new one.
extension DoseOccurrenceCopies on DoseOccurrence {
  /// This dose answered with [value], as the server saved it.
  DoseOccurrence withRecord(DoseRecord value) => DoseOccurrence(
    planId: planId,
    scheduleId: scheduleId,
    scheduledOn: scheduledOn,
    time: time,
    name: name,
    strengthValue: strengthValue,
    strengthUnit: strengthUnit,
    dosageForm: dosageForm,
    doseValue: doseValue,
    doseUnit: doseUnit,
    missedAfterMinutes: missedAfterMinutes,
    instructions: instructions,
    reason: reason,
    record: value,
    timingState: null,
  );

  /// This dose put off by [value], as the server keeps it.
  DoseOccurrence withSnooze(SharedSnooze? value) => DoseOccurrence(
    planId: planId,
    scheduleId: scheduleId,
    scheduledOn: scheduledOn,
    time: time,
    name: name,
    strengthValue: strengthValue,
    strengthUnit: strengthUnit,
    dosageForm: dosageForm,
    doseValue: doseValue,
    doseUnit: doseUnit,
    missedAfterMinutes: missedAfterMinutes,
    instructions: instructions,
    reason: reason,
    record: record,
    timingState: timingState,
    snooze: value,
  );
}
