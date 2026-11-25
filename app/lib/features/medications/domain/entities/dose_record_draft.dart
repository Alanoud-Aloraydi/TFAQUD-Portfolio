import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:equatable/equatable.dart';

/// The answer to a dose before it is sent: taken at [takenAt] (a real
/// moment, sent in UTC), or skipped with an optional reason.
class DoseRecordDraft extends Equatable {
  const DoseRecordDraft({
    required this.outcome,
    this.takenAt,
    this.skipReasonCode,
    this.skipReasonNote,
  });

  final DoseOutcome outcome;
  final DateTime? takenAt;
  final String? skipReasonCode;
  final String? skipReasonNote;

  /// The body of `PUT medication-dose-records/{schedule}/{day}`.
  Map<String, Object?> toJson() => {
    'outcome': outcome.name,
    'taken_at': takenAt?.toUtc().toIso8601String(),
    'skip_reason_code': skipReasonCode,
    'skip_reason_note': skipReasonNote,
  };

  @override
  List<Object?> get props => [outcome, takenAt, skipReasonCode, skipReasonNote];
}

/// Whether a dose was taken late, which the «بعد الموعد» line asks.
extension DoseLateness on DoseOccurrence {
  /// Whether the dose was taken at or after its missed boundary,
  /// [missedAfterMinutes] after its time on the patient's [clock] (the
  /// «بعد الموعد» status). False when it was not taken.
  bool isTakenLate(PatientClock clock) {
    final DateTime? takenAt = record?.takenAt;
    if (record?.outcome != DoseOutcome.taken || takenAt == null) return false;
    final DateTime boundary = clock
        .momentOf(scheduledOn, time)
        .add(Duration(minutes: missedAfterMinutes));
    return !takenAt.toUtc().isBefore(boundary);
  }
}

/// Why a dose was not taken, as offered on the skip sheet.
enum DoseSkipReason {
  forgotten,
  unavailable,
  sideEffects,
  patientRefused,
  other;

  /// The API's word for the reason.
  String get apiValue => switch (this) {
    sideEffects => 'side_effects',
    patientRefused => 'patient_refused',
    _ => name,
  };
}
