import 'dart:async';

import 'package:app/app/services/notifications/tap_inbox.dart';
import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/service_texts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// [PhoneNotifications] with the flutter_local_notifications plugin, on
/// iOS and Android; on the web and desktop nothing is shown.
class PluginPhoneNotifications implements PhoneNotifications {
  /// [pushTaps]: the `kind` of each tapped server push (`RemotePush.taps`).
  PluginPhoneNotifications({this._pushTaps = const Stream<String>.empty()});

  final Stream<String> _pushTaps;
  final _plugin = FlutterLocalNotificationsPlugin();
  final TapInbox _inbox = TapInbox();
  final NativeReminderTaps _nativeTaps = const NativeReminderTaps();
  bool _ready = false;

  @override
  Future<void> initialize() async {
    if (!runsOnPhone) return;
    await _plugin.initialize(
      settings: notificationInitializationSettings(),
      onDidReceiveNotificationResponse: (NotificationResponse response) =>
          _inbox.deliverResponse(response.payload, response.actionId),
    );
    await listenForNotificationTaps(_plugin, _nativeTaps, _inbox);
    await _plugin.android?.createNotificationChannel(reminderChannel);
    listenToPushTaps();
    _ready = true;
    // Android plays the channel's sound; the chime is iOS's.
    if (runsOnIOS) unawaited(installNotificationSound());
  }

  /// Joins the taps on server pushes to [taps] and [takeLaunchTap].
  @visibleForTesting
  void listenToPushTaps() => _pushTaps.listen((String kind) {
    if (kind.isEmpty) return;
    deliverTap(pushTap(kind));
  });

  /// Gives [tap] to the page that listens; see [TapInbox.deliver].
  @visibleForTesting
  void deliverTap(String tap) => _inbox.deliver(tap);

  @override
  Future<AppPermission> permission() async =>
      _ready ? readNotificationPermission(_plugin) : AppPermission.notAsked;

  @override
  Future<bool> requestPermission() async =>
      _ready && await askNotificationPermission(_plugin);

  @override
  Future<Map<int, String>> pending() async {
    if (!_ready) return const <int, String>{};
    return pendingNotificationPayloads(_plugin);
  }

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    if (_ready) await scheduleNotification(_plugin, notification);
  }

  @override
  Future<void> cancel(int id) async {
    if (_ready) await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }

  @override
  Stream<String> get taps => _inbox.taps;

  @override
  String? takeLaunchTap() => _inbox.takeLaunchTap();
}

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

/// The app's reminders tapped on iOS, as its delegate keeps them
/// (AppDelegate.swift): from the first moment of a launch, so a reminder
/// that opens the closed app is not lost while Flutter's plugins are still
/// being registered.
class NativeReminderTaps {
  const NativeReminderTaps([
    this._channel = const MethodChannel('tafaqod/reminder_taps'),
  ]);

  final MethodChannel _channel;

  /// Gives [onTap] each tap: its payload, and the action pressed (empty for
  /// the reminder itself). The ones kept before come first.
  Future<void> listen(
    void Function(String payload, String action) onTap,
  ) async {
    void give(Object? tap) {
      if (tap case {
        'payload': final String payload,
        'action': final String action,
      }) {
        onTap(payload, action);
      }
    }

    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'tap') give(call.arguments);
    });
    try {
      final List<Object?> kept =
          await _channel.invokeListMethod<Object?>('listen') ?? <Object?>[];
      kept.forEach(give);
    } on MissingPluginException {
      // A build without the native side: its taps come from the plugin.
    }
  }
}

/// The iOS category of a reminder that can be put off; its one action.
const String reminderCategory = 'tafaqod.reminder';

/// The Android channel of the reminders. Android 8+ shows nothing without
/// a channel; the person can tune its sound and importance in Settings.
const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
  'tafaqod.reminders',
  ServiceTexts.channelName,
  description: ServiceTexts.channelDescription,
  importance: Importance.high,
);
