import 'dart:async';

import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// The dose reminders, kept in memory: what was synced, refreshed, cleared
/// and snoozed from a notification tap.
class FakeDoseReminders extends Fake implements DoseReminders {
  /// What [snoozeTap] answers.
  bool result = true;
  final List<String> snoozed = <String>[];
  final List<List<ReminderCircle>> synced = <List<ReminderCircle>>[];
  int refreshes = 0;
  int clears = 0;

  @override
  Future<void> sync(List<ReminderCircle> circles) async {
    synced.add(circles);
  }

  @override
  Future<void> refresh() async {
    refreshes++;
  }

  @override
  Future<void> clear() async => clears++;

  @override
  Future<bool> snoozeTap(String tap) async {
    snoozed.add(tap);
    return result;
  }
}

/// The calendar sync, kept in memory. [on] holds the switched-on
/// `circleId:category` pairs; everything else is counted.
class FakeCalendarSync extends Fake implements CalendarSync {
  FakeCalendarSync([Set<String>? on]) : on = on ?? <String>{};

  final Set<String> on;
  final List<List<ReminderCircle>> synced = <List<ReminderCircle>>[];
  int refreshes = 0;
  int clears = 0;

  @override
  Future<bool> isEnabled(
    String circleId,
    CalendarSyncCategory category,
  ) async => on.contains('$circleId:${category.name}');

  @override
  Future<void> setEnabled(
    String circleId,
    CalendarSyncCategory category,
    bool value,
  ) async {
    final String key = '$circleId:${category.name}';
    if (value) {
      on.add(key);
    } else {
      on.remove(key);
    }
  }

  @override
  Future<bool> isCircleEnabled(String circleId) async =>
      CalendarSyncCategory.values.any(
        (CalendarSyncCategory category) =>
            on.contains('$circleId:${category.name}'),
      );

  @override
  Future<void> setCircleEnabled(String circleId, bool value) async {
    for (final CalendarSyncCategory category in CalendarSyncCategory.values) {
      await setEnabled(circleId, category, value);
    }
  }

  @override
  Future<void> sync(List<ReminderCircle> circles) async {
    synced.add(circles);
  }

  @override
  Future<void> refresh() async {
    refreshes++;
  }

  @override
  Future<void> clear() async => clears++;
}
