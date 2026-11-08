import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart' as tz;

/// The app's own notification sound: a soft two-note chime, calm like the
/// app's words. The server's pushes name the same file (`sender.py`), so a
/// reminder set on the phone and a push from the server sound the same.
///
/// iOS looks for a notification sound in the app's `Library/Sounds` folder
/// (and in the main bundle). A Flutter asset is not in the main bundle, so
/// [PluginPhoneNotifications.initialize] copies it to `Library/Sounds`; until
/// then, and if the copy ever fails, iOS plays its default sound.
const String notificationSound = 'tafaqod_chime.wav';

/// Where the sound is in the app's assets.
const String notificationSoundAsset = 'assets/sounds/$notificationSound';

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

/// The iOS category of a reminder that can be put off; its one action.
const String reminderCategory = 'tafaqod.reminder';
const String snoozeAction = 'snooze';

/// How long «ذكّرني لاحقًا» puts a reminder off from the notification.
const Duration notificationSnooze = Duration(minutes: 15);

/// What [PhoneNotifications.taps] gives for the snooze action: this, then
/// the reminder's own payload.
const String snoozeTapPrefix = 'snooze-action:';

/// Whether [tap] is the snooze action of a reminder, not a plain tap.
bool isSnoozeTap(String tap) => tap.startsWith(snoozeTapPrefix);

/// The notifications the app sets on the phone itself (no server and no
/// Apple push needed). Behind an interface, so the tests run without the
/// iOS plugin.
abstract interface class PhoneNotifications {
  /// Prepares the plugin without asking for permission, and keeps the tap
  /// that opened the app, if any.
  Future<void> initialize();

  /// Asks whether the app may show notifications. iOS shows its question
  /// only the first time; later calls answer at once. True when allowed.
  Future<bool> requestPermission();

  /// The scheduled notifications that have not shown yet: id to payload.
  Future<Map<int, String>> pending();

  /// Sets [notification]; one with the same id is replaced.
  Future<void> schedule(ScheduledNotification notification);

  Future<void> cancel(int id);

  /// Removes every notification of the app, scheduled and shown.
  Future<void> cancelAll();

  /// The payload of each notification the person taps while the app runs.
  Stream<String> get taps;

  /// The payload of the notification that opened the app, once.
  String? takeLaunchTap();
}

/// [PhoneNotifications] with the flutter_local_notifications plugin. The app
/// is for iPhone, so on other platforms nothing is shown.
class PluginPhoneNotifications implements PhoneNotifications {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _taps = StreamController<String>.broadcast();
  String? _launchTap;
  bool _ready = false;

  @override
  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    await _plugin.initialize(
      // Permission is asked later, when there is something to remind.
      settings: InitializationSettings(
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
                  'ذكّرني بعد 15 دقيقة',
                  options: <DarwinNotificationActionOption>{
                    DarwinNotificationActionOption.foreground,
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? tap = _tapOf(response);
        if (tap != null) _taps.add(tap);
      },
    );
    final NotificationAppLaunchDetails? launch = await _plugin
        .getNotificationAppLaunchDetails();
    final NotificationResponse? response = launch?.notificationResponse;
    final String? tap = response == null ? null : _tapOf(response);
    if ((launch?.didNotificationLaunchApp ?? false) && tap != null) {
      _launchTap = tap;
    }
    _ready = true;
    unawaited(_installSound());
  }

  /// The payload of a tap, or [snoozeTapPrefix] and the payload for the
  /// snooze action; null without a payload.
  static String? _tapOf(NotificationResponse response) {
    final String? payload = response.payload;
    if (payload == null || payload.isEmpty) return null;
    return response.actionId == snoozeAction
        ? '$snoozeTapPrefix$payload'
        : payload;
  }

  /// Copies [notificationSound] to `Library/Sounds`, where iOS finds it for
  /// the reminders and the pushes. Done once; a failure leaves iOS's default
  /// sound, which is still a sound.
  Future<void> _installSound() async {
    try {
      final Directory library = await getLibraryDirectory();
      final File file = File('${library.path}/Sounds/$notificationSound');
      final data = await rootBundle.load(notificationSoundAsset);
      if (file.existsSync() && file.lengthSync() == data.lengthInBytes) {
        return;
      }
      await file.parent.create(recursive: true);
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
    } on Exception catch (error) {
      debugPrint('The notification sound was not copied: $error');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final IOSFlutterLocalNotificationsPlugin? ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<Map<int, String>> pending() async {
    if (!_ready) return const <int, String>{};
    final List<PendingNotificationRequest> requests = await _plugin
        .pendingNotificationRequests();
    return <int, String>{
      for (final PendingNotificationRequest request in requests)
        request.id: request.payload ?? '',
    };
  }

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    if (!_ready) return;
    await _plugin.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      // An exact moment: given in UTC, it fires at the right time whatever
      // the phone's time zone is.
      scheduledDate: tz.TZDateTime.from(notification.at.toUtc(), tz.UTC),
      notificationDetails: NotificationDetails(
        iOS: DarwinNotificationDetails(
          threadIdentifier: notification.thread,
          // With the sound, also when the app is open.
          presentSound: true,
          sound: notificationSound,
          categoryIdentifier: notification.snoozable ? reminderCategory : null,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: notification.payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  @override
  Stream<String> get taps => _taps.stream;

  @override
  String? takeLaunchTap() {
    final String? tap = _launchTap;
    _launchTap = null;
    return tap;
  }
}
