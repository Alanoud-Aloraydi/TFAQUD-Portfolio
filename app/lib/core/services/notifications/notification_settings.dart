import 'package:app/core/services/notifications/notification_taps.dart';
import 'package:app/core/services/notifications/reminder_channel.dart';
import 'package:app/core/services/service_texts.dart';
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
