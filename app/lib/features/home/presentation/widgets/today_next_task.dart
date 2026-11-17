import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/appointment_attend_window.dart';
import 'package:app/features/home/domain/day_task_times.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/measurement_timing.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// The earliest open task of today: exactly one of [medication],
/// [measurement] and [appointment] is set, and [at] is its wall time.
typedef NextTask = ({
  DateTime at,
  DoseOccurrence? medication,
  MeasurementOccurrence? measurement,
  CareAppointment? appointment,
});

/// Selects the earliest open task from today's and future schedules, all
/// on the patient's wall clock ([now]). A visit counts only on its own
/// day; past its time and still open, it stays until another task of the
/// day comes after it (then it waits in «يحتاج انتباهك»).
NextTask? nearestTask(
  DateTime now,
  List<DoseOccurrence> medications,
  List<MeasurementOccurrence> measurements,
  List<CareAppointment> appointments,
) {
  final DateTime today = scheduleDay(now);
  final List<DateTime> times = dayTaskTimes(
    today,
    doses: medications,
    measurements: measurements,
    visits: appointments,
  );
  final candidates = <NextTask>[
    for (final item in medications)
      if (medicationIsNextTaskCandidate(item, now))
        (
          at: wallClockAt(item.scheduledOn, item.time).isBefore(now)
              ? now
              : wallClockAt(item.scheduledOn, item.time),
          medication: item,
          measurement: null,
          appointment: null,
        ),
    for (final item in measurements)
      if (measurementIsNextTaskCandidate(item, now))
        (
          at: wallClockAt(item.scheduledOn, item.time).isBefore(now)
              ? now
              : wallClockAt(item.scheduledOn, item.time),
          medication: null,
          measurement: item,
          appointment: null,
        ),
    for (final item in appointments)
      if (item.status == AppointmentStatus.scheduled &&
          scheduleDay(item.scheduledOn) == today &&
          (!item.scheduledAt.isBefore(now) || !item.overtakenAt(now, times)))
        (
          at: item.scheduledAt.isBefore(now) ? now : item.scheduledAt,
          medication: null,
          measurement: null,
          appointment: item,
        ),
  ]..sort((a, b) => a.at.compareTo(b.at));
  return candidates.firstOrNull;
}
