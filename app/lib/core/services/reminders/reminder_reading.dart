import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/reminder_limits.dart';
import 'package:app/core/services/reminders/reminder_sources.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/appointments/domain/use_cases/appointments_use_case.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// What the reminders are planned from: the tasks of every circle, and the
/// moment the reminders end ([until]).
class ReminderReading {
  final List<(ReminderCircle, DoseOccurrence)> doses =
      <(ReminderCircle, DoseOccurrence)>[];
  final List<(ReminderCircle, MeasurementOccurrence)> measurements =
      <(ReminderCircle, MeasurementOccurrence)>[];
  final List<(ReminderCircle, CareAppointment)> appointments =
      <(ReminderCircle, CareAppointment)>[];
  DateTime? until;
}

/// Reads [reminderDays] of each of [circles]' own patient's days; the
/// reminders end together at the first patient midnight after them. Null
/// when a reading failed or [stale] says the run is over: the reminders
/// already set stay until the next reading.
Future<ReminderReading?> readReminders({
  required List<ReminderCircle> circles,
  required DateTime now,
  required ReminderSources sources,
  required bool Function() stale,
}) async {
  final ReminderReading reading = ReminderReading();
  for (final ReminderCircle circle in circles) {
    // Days as UTC dates, so the phone's own DST never moves one.
    final DateTime today = circle.clock.today(now);
    final DateTime from = DateTime.utc(today.year, today.month, today.day);
    final DateTime to = from.add(const Duration(days: reminderDays - 1));
    final DateTime end = circle.clock.momentOf(
      from.add(const Duration(days: reminderDays)),
      '00:00',
    );
    final DateTime? until = reading.until;
    if (until == null || end.isBefore(until)) reading.until = end;
    final result = await sources.medications.getOccurrences(
      circle.id,
      from,
      to,
    );
    if (stale()) return null;
    final List<DoseOccurrence>? list = result.tryGetSuccess();
    // Offline or refused: the reminders already set stay until the next
    // reading.
    if (list == null) return null;
    for (final DoseOccurrence dose in list) {
      reading.doses.add((circle, dose));
    }
    try {
      final MeasurementsUseCase? measurementTasks = sources.measurements;
      if (measurementTasks != null) {
        final List<MeasurementOccurrence> tasks = await measurementTasks
            .occurrences(circle.id, from, to);
        if (stale()) return null;
        for (final MeasurementOccurrence task in tasks) {
          reading.measurements.add((circle, task));
        }
      }
      final AppointmentsUseCase? appointmentTasks = sources.appointments;
      if (appointmentTasks != null) {
        final List<CareAppointment> visits = await appointmentTasks
            .appointments(circle.id);
        if (stale()) return null;
        for (final CareAppointment visit in visits) {
          // Only the patient and the members going with them.
          if (circle.remindsOfAppointment(visit.companionIds)) {
            reading.appointments.add((circle, visit));
          }
        }
      }
    } on Exception {
      // The same as a failed dose reading: keep what is set.
      return null;
    }
  }
  return reading;
}
