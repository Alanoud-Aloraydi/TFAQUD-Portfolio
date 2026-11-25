import 'package:app/app/services/permissions/app_permission.dart';
import 'package:equatable/equatable.dart';

export 'package:app/app/services/notifications/notification_sound.dart';
export 'package:app/app/services/notifications/plugin_phone_notifications.dart';

/// The notifications the app sets on the phone itself, on iOS and Android;
/// behind an interface, so the tests run without the plugin.
abstract interface class PhoneNotifications {
  /// Prepares the plugin without asking for permission, and keeps the tap
  /// that opened the app, if any.
  Future<void> initialize();

  /// Asks whether the app may show notifications (iOS and Android 13+ ask
  /// only the first time). True when allowed.
  Future<bool> requestPermission();

  /// What the phone allows now, without asking anything. Read it again on
  /// every resume: the person may have changed it in the phone's Settings.
  Future<AppPermission> permission();

  /// The scheduled notifications that have not shown yet: id to payload.
  Future<Map<int, String>> pending();

  /// Sets [notification]; one with the same id is replaced.
  Future<void> schedule(ScheduledNotification notification);

  Future<void> cancel(int id);

  /// Removes every notification of the app, scheduled and shown.
  Future<void> cancelAll();

  /// The payload of each notification tapped while a page listens.
  Stream<String> get taps;

  /// The payload of a tap no page heard yet (the one that opened the
  /// app), once.
  String? takeLaunchTap();
}

/// One notification the phone shows at [at], even when the app is closed.
///
/// [payload] says what it is about (the app reads it when the person taps
/// it), and [thread] stacks the notifications of one person together.
class ScheduledNotification extends Equatable {
  const ScheduledNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
    this.thread,
    this.snoozable = false,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String payload;
  final String? thread;

  /// Whether the notification offers «ذكّرني بعد 15 دقيقة» when pressed
  /// and held (a dose or a measurement).
  final bool snoozable;

  @override
  List<Object?> get props => [id, at, title, body, payload, thread, snoozable];
}
