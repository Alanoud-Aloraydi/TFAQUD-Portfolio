import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// The keys of the tasks someone else in the circle put off, still
/// waiting: the server reminds this phone of them at the new time.
Set<String> putOffByOthers(
  List<(ReminderCircle, DoseOccurrence)> doses,
  List<(ReminderCircle, MeasurementOccurrence)> measurements,
  DateTime now,
) => <String>{
  for (final (ReminderCircle circle, DoseOccurrence dose) in doses)
    if (dose.snooze?.waitsAt(now) ?? false) doseSnoozeKey(circle.id, dose),
  for (final (ReminderCircle circle, MeasurementOccurrence task)
      in measurements)
    if (task.snooze?.waitsAt(now) ?? false)
      measurementSnoozeKey(circle.id, task),
};
