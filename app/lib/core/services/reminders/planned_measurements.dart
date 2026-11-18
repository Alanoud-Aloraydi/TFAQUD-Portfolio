import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/dose_reminder_texts.dart';
import 'package:app/core/services/reminders/planned_reminder.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';

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
