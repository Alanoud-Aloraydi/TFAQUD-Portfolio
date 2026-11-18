import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminders/dose_reminder_texts.dart';
import 'package:app/core/services/reminders/planned_reminder.dart';
import 'package:app/core/services/reminders/reminder_limits.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';

/// The [kept] reminders with their ids, then the note to open the app
/// after the last one.
List<ScheduledNotification> numberedReminders(
  List<PlannedReminder> kept,
  DoseReminderTexts texts,
) => <ScheduledNotification>[
  for (int i = 0; i < kept.length; i++)
    ScheduledNotification(
      id: reminderIdBase + i,
      at: kept[i].at,
      title: kept[i].title,
      body: kept[i].body,
      // A dose or measurement carries its words and which task it is,
      // for «ذكّرني لاحقًا».
      payload: kept[i].snoozable
          ? payloadWithText(
              kept[i].payloadHead,
              kept[i].title,
              kept[i].body,
              snoozeKey: kept[i].snoozeKey,
              subject: kept[i].subject,
            )
          : kept[i].payloadHead,
      thread: kept[i].circle.id,
      snoozable: kept[i].snoozable,
    ),
  if (kept.isNotEmpty)
    ScheduledNotification(
      id: reminderIdBase + maxDoseReminders,
      at: kept.last.at.add(const Duration(minutes: 1)),
      title: texts.keepTitle(),
      body: texts.keepBody(),
      payload: keepRemindersPayload,
    ),
];
