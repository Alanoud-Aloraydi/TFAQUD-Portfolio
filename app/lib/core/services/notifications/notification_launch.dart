import 'package:app/core/services/notifications/notification_platforms.dart';
import 'package:app/core/services/notifications/tap_inbox.dart';
import 'package:app/core/services/reminders/native_reminder_taps.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
