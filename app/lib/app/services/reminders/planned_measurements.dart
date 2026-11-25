import 'package:app/app/services/reminder_circle.dart';
import 'package:app/app/services/reminders/dose_reminder_texts.dart';
import 'package:app/app/services/reminders/reminder_permission.dart';
import 'package:app/core/reminders/item_keys.dart';
import 'package:app/core/reminders/reminder_payloads.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

/// One reminder at each of [measurements] not recorded yet, inside the
/// window ([inWindow]) and not put off ([snoozed], by its key).
List<PlannedReminder> plannedMeasurements(
  List<(ReminderCircle, MeasurementOccurrence)> measurements,
  DoseReminderTexts texts,
  bool Function(DateTime at) inWindow,
  Set<String> snoozed,
) => <PlannedReminder>[
  for (final (ReminderCircle circle, MeasurementOccurrence task)
      in measurements)
    if (task.record == null &&
        (task.status == MeasurementStatus.upcoming ||
            task.status == MeasurementStatus.due) &&
        inWindow(circle.clock.momentOf(task.scheduledOn, task.time)) &&
        !snoozed.contains(measurementSnoozeKey(circle.id, task)))
      PlannedReminder(
        at: circle.clock.momentOf(task.scheduledOn, task.time),
        circle: circle,
        title: texts.measurementTitle(circle),
        body: texts.measurementBody(circle, task),
        prefix: measurementReminderPayload,
        snoozeKey: measurementSnoozeKey(circle.id, task),
        subject: task.kind.name,
      ),
];

/// One reminder at each of [doses] not recorded yet, inside the window
/// ([inWindow]) and not put off ([snoozed], by its key).
List<PlannedReminder> plannedDoses(
  List<(ReminderCircle, DoseOccurrence)> doses,
  DoseReminderTexts texts,
  bool Function(DateTime at) inWindow,
  Set<String> snoozed,
) => <PlannedReminder>[
  for (final (ReminderCircle circle, DoseOccurrence dose) in doses)
    if (dose.record == null &&
        inWindow(doseMoment(circle.clock, dose)) &&
        !snoozed.contains(doseSnoozeKey(circle.id, dose)))
      PlannedReminder(
        at: doseMoment(circle.clock, dose),
        circle: circle,
        title: texts.title(circle, dose),
        body: texts.body(circle, dose),
        prefix: doseReminderPayload,
        snoozeKey: doseSnoozeKey(circle.id, dose),
        subject: dose.name,
      ),
];

/// One reminder of the plan before it gets its id.
class PlannedReminder {
  const PlannedReminder({
    required this.at,
    required this.circle,
    required this.title,
    required this.body,
    required this.prefix,
    this.snoozeKey,
    this.subject,
    this.appointmentId,
  });

  final DateTime at;
  final ReminderCircle circle;
  final String title;
  final String body;
  final String prefix;

  /// A dose's or measurement's, which can be put off.
  final String? snoozeKey;
  final String? subject;

  /// A visit's, so a tap on its reminder opens that visit.
  final String? appointmentId;

  bool get snoozable => snoozeKey != null;

  /// The start of its payload: its kind and circle, and a visit's id.
  String get payloadHead => switch (appointmentId) {
    final String id => '$prefix${circle.id}$appointmentIdMark$id',
    null => '$prefix${circle.id}',
  };
}
