import 'package:app/core/reminders/task_snooze.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

/// The phone's reminders and calendar copy, as the simplified mode keeps
/// them. The app's own reminder and calendar services stand behind it, the
/// same ones the detailed mode uses.
abstract interface class SimplifiedReminders {
  /// Keeps the reminders, and the calendar copy the person chose, set for
  /// [day]'s circle.
  Future<void> keep(SimplifiedDay day);

  /// Reads the week of reminders again.
  Future<void> refresh();

  /// Puts [dose] of [circleId] off: its reminder, its card and its
  /// calendar copy move to [after] from now.
  Future<void> snoozeDose(String circleId, DoseOccurrence dose, Duration after);

  /// The same for [measurement].
  Future<void> snoozeMeasurement(
    String circleId,
    MeasurementOccurrence measurement,
    Duration after,
  );

  /// «ذكّرني لاحقًا» pressed in a notification: its task comes again.
  /// False when [tap] is not that button.
  Future<bool> snoozeTap(String tap);

  /// The tasks put off, by their snooze keys, until each comes again.
  ValueListenable<Map<String, TaskSnooze>> get snoozes;
}
