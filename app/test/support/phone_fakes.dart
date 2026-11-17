import 'dart:async';

import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/remote_push.dart';
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

  /// What [permission] answers; granted unless a test sets another.
  AppPermission allowed = AppPermission.granted;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<AppPermission> permission() async => allowed;

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
  FakeCalendarSync([Set<String>? on, this.access = AppPermission.granted])
    : on = on ?? <String>{};

  final Set<String> on;
  final List<List<ReminderCircle>> synced = <List<ReminderCircle>>[];
  int refreshes = 0;
  int clears = 0;

  /// What the phone's calendar answers. A test of a refused calendar sets
  /// it to [AppPermission.denied] before the ask, or to
  /// [AppPermission.notAsked] to have [requestPermission] decide.
  AppPermission access;

  /// What [requestPermission] gives once asked; null keeps [access].
  AppPermission? grantOnRequest;

  /// How many times the phone was asked, so a test can tell «asked and
  /// allowed» from «allowed all along».
  int requests = 0;

  @override
  Future<AppPermission> permission() async => access;

  @override
  Future<AppPermission> requestPermission() async {
    requests++;
    return access = grantOnRequest ?? access;
  }

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

/// The server's pushes (OneSignal), in memory: who signed in and out, the
/// permission asks, and a subscription id the test sets with [register].
class FakeRemotePush implements RemotePush {
  final StreamController<String> tapController =
      StreamController<String>.broadcast();
  final List<String> signIns = <String>[];
  final List<RemotePushObserver> observers = <RemotePushObserver>[];
  int signOuts = 0;
  int permissionRequests = 0;
  String? id;

  /// OneSignal's servers give this phone [subscriptionId].
  void register(String subscriptionId) {
    id = subscriptionId;
    for (final RemotePushObserver observer in List.of(observers)) {
      observer(subscriptionId);
    }
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> signIn(String accountId) async => signIns.add(accountId);

  @override
  Future<void> signOut() async => signOuts++;

  @override
  String? get subscriptionId => id;

  @override
  void addSubscriptionObserver(RemotePushObserver observer) =>
      observers.add(observer);

  @override
  void removeSubscriptionObserver(RemotePushObserver observer) =>
      observers.remove(observer);

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  /// Each [setWanted], in order.
  final List<bool> wanted = <bool>[];

  @override
  Future<void> setWanted(bool wanted) async => this.wanted.add(wanted);

  @override
  Stream<String> get taps => tapController.stream;
}
