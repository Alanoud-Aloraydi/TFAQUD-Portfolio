import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// The wall times of every task of [today]: its doses, readings and
/// visits, answered or not. A visit past its time stays the task of the
/// moment until the next of these comes (`overtakenAt`).
List<DateTime> dayTaskTimes(
  DateTime today, {
  required Iterable<DoseOccurrence> doses,
  required Iterable<MeasurementOccurrence> measurements,
  required Iterable<CareAppointment> visits,
}) {
  bool onDay(DateTime day) =>
      day.year == today.year &&
      day.month == today.month &&
      day.day == today.day;
  return <DateTime>[
    for (final DoseOccurrence dose in doses)
      if (onDay(dose.scheduledOn)) wallClockAt(dose.scheduledOn, dose.time),
    for (final MeasurementOccurrence task in measurements)
      if (onDay(task.scheduledOn)) wallClockAt(task.scheduledOn, task.time),
    for (final CareAppointment visit in visits)
      if (onDay(visit.scheduledOn)) visit.scheduledAt,
  ];
}
