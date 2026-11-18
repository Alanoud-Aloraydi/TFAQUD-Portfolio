import 'package:app/core/services/notifications/notification_sound.dart';
import 'package:app/core/services/notifications/notification_taps.dart';
import 'package:app/core/services/notifications/reminder_channel.dart';
import 'package:app/core/services/notifications/scheduled_notification.dart';
import 'package:app/core/services/service_texts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// How the phone shows [notification], on iOS and on Android.
NotificationDetails notificationDetailsOf(ScheduledNotification notification) =>
    NotificationDetails(
      iOS: DarwinNotificationDetails(
        threadIdentifier: notification.thread,
        // With the sound, also when the app is open.
        presentSound: true,
        sound: notificationSound,
        categoryIdentifier: notification.snoozable ? reminderCategory : null,
        // A task due (a dose, a reading, a visit): shown through a Focus
        // and the Scheduled Summary (Time Sensitive, Runner.entitlements).
        // The note to open the app, which has no person's thread: usual.
        interruptionLevel: notification.thread != null
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
      android: AndroidNotificationDetails(
        reminderChannel.id,
        reminderChannel.name,
        channelDescription: reminderChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        groupKey: notification.thread,
        // The snooze opens the app, which sets the reminder again.
        actions: notification.snoozable
            ? const <AndroidNotificationAction>[
                AndroidNotificationAction(
                  snoozeAction,
                  ServiceTexts.snoozeAction,
                  showsUserInterface: true,
                ),
              ]
            : null,
      ),
    );
