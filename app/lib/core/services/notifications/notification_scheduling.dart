import 'package:app/core/services/notifications/notification_details.dart';
import 'package:app/core/services/notifications/notification_platforms.dart';
import 'package:app/core/services/notifications/scheduled_notification.dart';
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
