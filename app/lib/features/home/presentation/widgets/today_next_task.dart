import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/measurements/domain/measurement.dart';
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
/// on the patient's wall clock ([now]).
NextTask? nearestTask(
  DateTime now,
  List<DoseOccurrence> medications,
  List<MeasurementOccurrence> measurements,
  List<CareAppointment> appointments,
) {
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
      if (item.record == null &&
          !wallClockAt(item.scheduledOn, item.time).isBefore(now))
        (
          at: wallClockAt(item.scheduledOn, item.time),
          medication: null,
          measurement: item,
          appointment: null,
        ),
    for (final item in appointments)
      if (item.status == AppointmentStatus.scheduled &&
          !wallClockAt(item.scheduledOn, item.time).isBefore(now))
        (
          at: wallClockAt(item.scheduledOn, item.time),
          medication: null,
          measurement: null,
          appointment: item,
        ),
  ]..sort((a, b) => a.at.compareTo(b.at));
  return candidates.firstOrNull;
}
