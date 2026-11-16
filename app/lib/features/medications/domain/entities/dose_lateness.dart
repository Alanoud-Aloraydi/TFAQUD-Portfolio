import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

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
