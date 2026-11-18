import 'package:app/core/utils/recordable_now.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/measurements/domain/measurement.dart';

/// Whether [task] can still be answered at [now] (the patient's wall time):
/// not once it is resolved or [readOnly], and only until the next task of
/// its kind is due.
bool canRecordMeasurement(
  MeasurementOccurrence task,
  DateTime now, {
  required bool readOnly,
}) {
  final bool resolved =
      task.status != MeasurementStatus.upcoming &&
      task.status != MeasurementStatus.due &&
      task.status != MeasurementStatus.missed;
  return !readOnly &&
      canRecordOccurrence(
        resolved: resolved,
        scheduledAt: wallClockAt(task.scheduledOn, task.time),
        now: now,
      );
}
