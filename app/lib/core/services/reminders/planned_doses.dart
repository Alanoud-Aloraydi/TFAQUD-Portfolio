import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/dose_reminder_texts.dart';
import 'package:app/core/services/reminders/planned_reminder.dart';
import 'package:app/core/services/reminders/reminder_moments.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

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
