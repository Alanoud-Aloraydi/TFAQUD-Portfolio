import 'package:app/app/services/notifications/notification_sound.dart';
import 'package:app/app/services/notifications/reminder_channel.dart';
import 'package:app/app/services/notifications/scheduled_notification.dart';
import 'package:app/app/services/notifications/tap_inbox.dart';
import 'package:app/app/services/reminders/native_reminder_taps.dart';
import 'package:app/app/services/service_texts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Sets [notification] with [plugin]; one with the same id is replaced.
Future<void> scheduleNotification(
  FlutterLocalNotificationsPlugin plugin,
  ScheduledNotification notification,
) async => plugin.zonedSchedule(
  id: notification.id,
  title: notification.title,
  body: notification.body,
  // An exact moment: given in UTC, it fires at the right time whatever
  // the phone's time zone is.
  scheduledDate: tz.TZDateTime.from(notification.at.toUtc(), tz.UTC),
  notificationDetails: notificationDetailsOf(notification),
  androidScheduleMode: await _androidMode(plugin),
  payload: notification.payload,
);

/// At the exact minute when Android allows exact alarms (granted by
/// default before Android 14; a setting after); otherwise Android may
/// delay it a few minutes to save battery, which beats not showing it.
Future<AndroidScheduleMode> _androidMode(
  FlutterLocalNotificationsPlugin plugin,
) async => (await plugin.android?.canScheduleExactNotifications() ?? false)
    ? AndroidScheduleMode.exactAllowWhileIdle
    : AndroidScheduleMode.inexactAllowWhileIdle;

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

/// Joins the taps on notifications to [inbox], the one that opened the app
/// included: on iOS from the app's delegate ([nativeTaps]), on Android from
/// the plugin.
Future<void> listenForNotificationTaps(
  FlutterLocalNotificationsPlugin plugin,
  NativeReminderTaps nativeTaps,
  TapInbox inbox,
) async {
  if (runsOnIOS) {
    await nativeTaps.listen(inbox.deliverResponse);
    return;
  }
  final NotificationAppLaunchDetails? launch = await plugin
      .getNotificationAppLaunchDetails();
  final NotificationResponse? response = launch?.notificationResponse;
  if ((launch?.didNotificationLaunchApp ?? false) && response != null) {
    inbox.deliverResponse(response.payload, response.actionId);
  }
}
