/// Which reminders the phone gets: a pure plan of the doses, measurements
/// and appointments to come ([planDoseReminders]), with the phone's limits
/// and the words given from outside ([DoseReminderTexts]). [DoseReminders]
/// reads the server and sets this plan on the phone.
library;

import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/reminder_circle.dart';
import 'package:app/app/services/reminders/dose_reminder_texts.dart';
import 'package:app/app/services/reminders/planned_appointments.dart';
import 'package:app/app/services/reminders/planned_measurements.dart';
import 'package:app/app/services/reminders/reminder_limits.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

export 'package:app/app/services/reminders/appointment_lead.dart';
export 'package:app/app/services/reminders/dose_reminder_texts.dart';
export 'package:app/app/services/reminders/reminder_limits.dart';
export 'package:app/app/services/reminders/reminder_permission.dart';

/// The reminders after [now], the nearest first, at most [limit]:
///
/// * one at each dose not recorded yet (taken or skipped);
/// * one at each measurement not recorded yet;
///
/// (a dose or measurement put off, by its key in [snoozed], has its own
/// reminder at the new time instead);
/// * two for each appointment still to come: a day before it, and its own
///   [CareAppointment.reminderLead] before it.
///
/// None at or after [until], so the reminders end together and the note
/// after the last one is not far behind the others. After the last one
/// comes a note to open the app, which fires only when the app was not
/// opened in all that time (each opening sets the reminders again, further
/// on).
List<ScheduledNotification> planDoseReminders({
  List<(ReminderCircle, DoseOccurrence)> doses =
      const <(ReminderCircle, DoseOccurrence)>[],
  List<(ReminderCircle, MeasurementOccurrence)> measurements =
      const <(ReminderCircle, MeasurementOccurrence)>[],
  List<(ReminderCircle, CareAppointment)> appointments =
      const <(ReminderCircle, CareAppointment)>[],
  required DateTime now,
  required DoseReminderTexts texts,
  DateTime? until,
  int limit = maxDoseReminders,
  Set<String> snoozed = const <String>{},
}) {
  // A moment in the next few seconds is too close to set: by the time the
  // phone has it, it may have passed.
  final DateTime earliest = now.toUtc().add(reminderMargin);
  bool inWindow(DateTime at) =>
      at.isAfter(earliest) && (until == null || at.isBefore(until));
  final List<PlannedReminder> upcoming = <PlannedReminder>[
    ...plannedDoses(doses, texts, inWindow, snoozed),
    ...plannedMeasurements(measurements, texts, inWindow, snoozed),
    ...plannedAppointments(appointments, texts, inWindow),
  ]..sort((PlannedReminder a, PlannedReminder b) => a.at.compareTo(b.at));
  return numberedReminders(upcoming.take(limit).toList(), texts);
}
