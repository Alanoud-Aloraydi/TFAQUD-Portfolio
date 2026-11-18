import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// A dose put off: its circle, its time of the plan, and its day.
String doseSnoozeKey(String circleId, DoseOccurrence dose) {
  final DateTime day = dose.scheduledOn;
  return '$circleId|${dose.scheduleId}|${day.year}-${day.month}-${day.day}';
}

/// A measurement put off: its circle, its plan's version, its time and its
/// day.
String measurementSnoozeKey(String circleId, MeasurementOccurrence task) {
  final DateTime day = task.scheduledOn;
  return '$circleId|measurement|${task.versionId}|${task.time}|'
      '${day.year}-${day.month}-${day.day}';
}
