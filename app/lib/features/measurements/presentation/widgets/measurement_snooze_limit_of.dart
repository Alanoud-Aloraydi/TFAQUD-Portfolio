import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:flutter/widgets.dart';

/// How long the measurement may still be put off: 12 hours, and never
/// past halfway to the reading that follows it, which the occurrence
/// carries as [MeasurementOccurrence.nextAt].
Duration measurementSnoozeLimitOf(
  BuildContext context,
  MeasurementOccurrence task,
) {
  final PatientClock clock = PatientClockScope.of(context);
  return snoozeLimit(
    now: DateTime.now().toUtc(),
    dose: clock.momentOf(task.scheduledOn, task.time),
    nextDose: task.nextAt,
  );
}
