import 'package:app/app/services/notifications/notification_sound.dart';
import 'package:app/app/services/notifications/reminder_channel.dart';
import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/app/services/service_texts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// How the plugin starts. Permission is asked later, when there is
/// something to remind.
InitializationSettings notificationInitializationSettings() =>
    InitializationSettings(
      // The white logo in the status bar, the one OneSignal's pushes use
      // too: Android draws a small icon as a silhouette, so the colored
      // launcher icon showed as a white square.
      android: const AndroidInitializationSettings(
        '@drawable/ic_stat_onesignal_default',
      ),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        // Press and hold a dose or measurement reminder: «ذكّرني بعد 15
        // دقيقة». It opens the app, which sets the reminder again (the
        // words are fixed here: the translations are not loaded yet).
        notificationCategories: <DarwinNotificationCategory>[
          DarwinNotificationCategory(
            reminderCategory,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                snoozeAction,
                ServiceTexts.snoozeAction,
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.foreground,
                },
              ),
            ],
          ),
        ],
      ),
    );

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

/// The notifications [plugin] has scheduled that have not shown yet: id to
/// payload.
Future<Map<int, String>> pendingNotificationPayloads(
  FlutterLocalNotificationsPlugin plugin,
) async {
  final List<PendingNotificationRequest> requests = await plugin
      .pendingNotificationRequests();
  return <int, String>{
    for (final PendingNotificationRequest request in requests)
      request.id: request.payload ?? '',
  };
}
