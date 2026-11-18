import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';

/// Where [dose] stands at the patient's wall time [wall].
TodayTaskStatus todayDoseStatus(DoseOccurrence dose, DateTime wall) {
  if (dose.record != null) return TodayTaskStatus.done;
  return switch (medicationTimingState(dose, wall)) {
    DoseTimingState.late || DoseTimingState.missed => TodayTaskStatus.late,
    _ => TodayTaskStatus.later,
  };
}

/// The server's status is read once; the deadline it sends keeps the
/// status right after that.
TodayTaskStatus todayMeasurementStatus(
  MeasurementOccurrence item,
  DateTime now,
) {
  if (item.record != null) return TodayTaskStatus.done;
  if (now.isAfter(item.deadlineAt)) return TodayTaskStatus.late;
  return TodayTaskStatus.later;
}

/// A visit is done once «حضرت» is said; one whose time came waits for it.
TodayTaskStatus todayAppointmentStatus(CareAppointment item, DateTime wall) {
  if (item.status == AppointmentStatus.completed) return TodayTaskStatus.done;
  return item.scheduledAt.isAfter(wall)
      ? TodayTaskStatus.later
      : TodayTaskStatus.late;
}

/// Time order; at the same time, doses before measurements before visits.
int todayTaskOrder(TodayTask a, TodayTask b) {
  final int byTime = a.scheduledAt.compareTo(b.scheduledAt);
  return byTime != 0 ? byTime : a.kind.index.compareTo(b.kind.index);
}

/// Whether [a] and [b] fall on the same calendar date.
bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
