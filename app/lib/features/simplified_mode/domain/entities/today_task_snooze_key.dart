import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';

/// The key a task is put off by, shared with the detailed mode.
extension TodayTaskSnoozeKey on TodayTask {
  /// The key its «ذكّرني لاحقًا» is kept by in [circleId], the same as
  /// the detailed mode's ([DoseReminders.snoozes]); null for an
  /// appointment, which is not put off.
  String? snoozeKey(String circleId) => switch ((dose, measurement)) {
    (final DoseOccurrence value, _) => doseSnoozeKey(circleId, value),
    (_, final MeasurementOccurrence value) => measurementSnoozeKey(
      circleId,
      value,
    ),
    _ => null,
  };
}
