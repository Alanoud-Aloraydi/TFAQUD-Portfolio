import 'dart:async';

import 'package:app/core/services/phone_notifications.dart';

/// The phone's notifications, kept in memory: what is scheduled, how often
/// the app asked for permission, and taps the test sends.
class FakePhoneNotifications implements PhoneNotifications {
  final Map<int, ScheduledNotification> scheduled =
      <int, ScheduledNotification>{};
  final StreamController<String> tapController =
      StreamController<String>.broadcast();

  int permissionRequests = 0;
  int cancelAlls = 0;
  String? launchTap;

  /// The scheduled notifications, the soonest first.
  List<ScheduledNotification> get inOrder => scheduled.values.toList()
    ..sort(
      (ScheduledNotification a, ScheduledNotification b) =>
          a.at.compareTo(b.at),
    );

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<Map<int, String>> pending() async => <int, String>{
    for (final MapEntry<int, ScheduledNotification> entry in scheduled.entries)
      entry.key: entry.value.payload,
  };

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    scheduled[notification.id] = notification;
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAlls++;
    scheduled.clear();
  }

  @override
  Stream<String> get taps => tapController.stream;

  @override
  String? takeLaunchTap() {
    final String? tap = launchTap;
    launchTap = null;
    return tap;
  }
}
