import 'package:app/core/services/notifications/notification_platforms.dart';
import 'package:app/core/services/permissions/app_permission.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// What the phone allows [plugin] to show now, without asking anything.
Future<AppPermission> readNotificationPermission(
  FlutterLocalNotificationsPlugin plugin,
) async {
  final AndroidFlutterLocalNotificationsPlugin? android = plugin.android;
  if (android != null) {
    final bool? enabled = await android.areNotificationsEnabled();
    return enabled == true ? AppPermission.granted : AppPermission.denied;
  }
  final NotificationsEnabledOptions? options = await plugin.ios
      ?.checkPermissions();
  if (options == null) return AppPermission.notAsked;
  if (options.isEnabled) return AppPermission.granted;
  // iOS «Deliver Quietly»: allowed, but with no alert and no sound.
  if (options.isProvisionalEnabled) return AppPermission.partial;
  return AppPermission.denied;
}

/// Asks whether [plugin] may show notifications. True when allowed.
Future<bool> askNotificationPermission(
  FlutterLocalNotificationsPlugin plugin,
) async {
  final AndroidFlutterLocalNotificationsPlugin? android = plugin.android;
  if (android != null) {
    return await android.requestNotificationsPermission() ?? false;
  }
  return await plugin.ios?.requestPermissions(alert: true, sound: true) ??
      false;
}
