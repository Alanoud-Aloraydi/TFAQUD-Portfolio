import 'dart:async';

import 'package:app/app/services/reminder_circle.dart';
import 'package:app/app/services/reminders/appointment_lead.dart';
import 'package:app/app/services/reminders/dose_snoozer.dart';
import 'package:app/app/services/reminders/snooze_ledger.dart';
import 'package:app/app/services/reminders/task_snooze.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:flutter/foundation.dart';

/// The words of the reminders. They are given from outside, so this file
/// needs no translations and the tests can use plain words.
class DoseReminderTexts {
  const DoseReminderTexts({
    required this.title,
    required this.body,
    required this.measurementTitle,
    required this.measurementBody,
    required this.appointmentTitle,
    required this.appointmentBody,
    required this.keepTitle,
    required this.keepBody,
  });

  /// «حان موعد الدواء».
  final String Function(ReminderCircle circle, DoseOccurrence dose) title;

  /// «يا ياسر، لا ننسى ميتفورمين» over the dose, «1 حبة، الساعة 9:00 م».
  final String Function(ReminderCircle circle, DoseOccurrence dose) body;

  /// «ياسر، وقت القياس الحين».
  final String Function(ReminderCircle circle) measurementTitle;

  /// What to measure, «سكر الدم».
  final String Function(
    ReminderCircle circle,
    MeasurementOccurrence measurement,
  )
  measurementBody;

  /// «ياسر! عندك موعد القلب بكرة», or «… بعد ساعتين».
  final String Function(
    ReminderCircle circle,
    AppointmentLead lead,
    CareAppointment appointment,
  )
  appointmentTitle;

  /// «الساعة 4:30 م، مستشفى الملك فهد».
  final String Function(CareAppointment appointment) appointmentBody;

  /// The last note: open the app so the reminders go on.
  final String Function() keepTitle;
  final String Function() keepBody;
}

/// The tasks put off with «ذكّرني لاحقًا», as [DoseReminders] gives them.
mixin DoseSnoozing {
  @protected
  DoseSnoozer get snoozer;

  /// The tasks put off and not yet reminded of again, by their keys: the
  /// cards of both modes show «بنذكّرك 2:36 م», and the calendar copy has
  /// an event at that time.
  ValueListenable<Map<String, TaskSnooze>> get snoozes {
    unawaited(snoozer.putter.ledger.read());
    return snoozer.putter.ledger.published;
  }

  /// Whether «ذكّرني لاحقًا» can remind of anything now: the switch is on
  /// and the phone lets the reminders through, or has not been asked. Both
  /// modes ask before the time is chosen, and say why when it cannot.
  Future<bool> canRemindLater() => remindersAllowed(
    snoozer.putter.enabled,
    snoozer.putter.permission,
    ask: false,
  );

  /// «ذكّرني لاحقًا» on [dose] of [circleId], in either mode: its reminder
  /// again [after] from now, with the words of its own reminder. False
  /// while the reminders are off ([canRemindLater]): nothing is put off.
  Future<bool> snoozeDose(
    String circleId,
    DoseOccurrence dose,
    Duration after,
  ) => snoozer.snoozeDose(circleId, dose, after);

  /// The same for a measurement [task].
  Future<bool> snoozeMeasurement(
    String circleId,
    MeasurementOccurrence task,
    Duration after,
  ) => snoozer.snoozeMeasurement(circleId, task, after);

  /// «ذكّرني لاحقًا» from a notification's snooze action [tap]; false when
  /// the tap is not a snoozable reminder.
  Future<bool> snoozeTap(String tap) => snoozer.snoozeTap(tap);
}
