import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

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
