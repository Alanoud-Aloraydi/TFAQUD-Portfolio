import 'dart:async';

import 'package:app/app/services/notifications/notification_scheduling.dart';
import 'package:app/app/services/notifications/notification_settings.dart';
import 'package:app/app/services/notifications/tap_inbox.dart';
import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/reminders/native_reminder_taps.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
