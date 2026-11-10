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

/// The words of [snoozeAction], fixed: the translations are not loaded
/// when the plugin starts.
const String _snoozeLabel = 'ذكّرني بعد 15 دقيقة';

/// The Android channel of the reminders. Android 8+ shows nothing without
/// a channel; the person can tune its sound and importance in Settings.
const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
  'tafaqod.reminders',
  'التذكيرات',
  description: 'تذكير الجرعات والقياسات والمواعيد',
  importance: Importance.high,
);

/// How long «ذكّرني لاحقًا» puts a reminder off from the notification.
const Duration notificationSnooze = Duration(minutes: 15);

/// What [PhoneNotifications.taps] gives for the snooze action: this, then
/// the reminder's own payload.
const String snoozeTapPrefix = 'snooze-action:';

/// Whether [tap] is the snooze action of a reminder, not a plain tap.
bool isSnoozeTap(String tap) => tap.startsWith(snoozeTapPrefix);

/// What [PhoneNotifications.taps] gives for a tapped server push (iOS):
/// this, then the push's `kind` (backend `app/push`).
const String pushTapPrefix = 'push:';

/// The server's `kind` of a tapped push, or null for a reminder's tap.
String? pushKind(String tap) =>
    tap.startsWith(pushTapPrefix) ? tap.substring(pushTapPrefix.length) : null;

/// The push kinds whose news waits in the notifications page (an invitation
/// or a request to answer); every other kind opens «اليوم».
const Set<String> inboxPushKinds = <String>{'invitation', 'circle_request'};

/// The notifications the app sets on the phone itself (no server and no
/// push needed), on iOS and Android. Behind an interface, so the tests run
/// without the plugin.
abstract interface class PhoneNotifications {
  /// Prepares the plugin without asking for permission, and keeps the tap
  /// that opened the app, if any.
  Future<void> initialize();

  /// Asks whether the app may show notifications. iOS and Android 13+
  /// show their question only the first time; later calls answer at once
  /// (older Android allows without asking). True when allowed.
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

/// [PhoneNotifications] with the flutter_local_notifications plugin, on
/// iOS and Android; on the web and desktop nothing is shown.
class PluginPhoneNotifications implements PhoneNotifications {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<String> _taps = StreamController<String>.broadcast();
  String? _launchTap;

  /// Taps on the server's pushes, which the plugin ignores: the iOS app
  /// delegate (AppDelegate.swift) sends their `kind` here.
  static const MethodChannel _pushTaps = MethodChannel('tafaqod/push_taps');
  bool _ready = false;

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// The plugin's Android side; null on iOS.
  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      return;
    }
    await _plugin.initialize(
      // Permission is asked later, when there is something to remind.
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
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
                  _snoozeLabel,
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
    await _android?.createNotificationChannel(reminderChannel);
    if (_isIOS) await listenToPushTaps();
    _ready = true;
    // Android plays the channel's sound; the chime is iOS's.
    if (_isIOS) unawaited(_installSound());
  }

  /// Joins the taps on server pushes to [taps] and [takeLaunchTap]. iOS
  /// keeps a tap that came before Dart listened (the push that launched the
  /// app) and gives it to `launchTap`; later taps arrive as `tap`. Android
  /// pushes need FCM, which the app does not have yet.
  @visibleForTesting
  Future<void> listenToPushTaps() async {
    _pushTaps.setMethodCallHandler((MethodCall call) async {
      final Object? kind = call.arguments;
      if (call.method != 'tap' || kind is! String || kind.isEmpty) return;
      // A tap that comes while no page listens yet (the app is still
      // starting) waits as the launch tap.
      if (_taps.hasListener) {
        _taps.add('$pushTapPrefix$kind');
      } else {
        _launchTap ??= '$pushTapPrefix$kind';
      }
    });
    try {
      final String? kind = await _pushTaps.invokeMethod<String>('launchTap');
      if (kind != null && kind.isNotEmpty) {
        _launchTap ??= '$pushTapPrefix$kind';
      }
    } on PlatformException {
      // No launch tap to give.
    } on MissingPluginException {
      // An app build without the channel.
    }
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
    final AndroidFlutterLocalNotificationsPlugin? android = _android;
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
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
                    _snoozeLabel,
                    showsUserInterface: true,
                  ),
                ]
              : null,
        ),
      ),
      androidScheduleMode: await _androidMode(),
      payload: notification.payload,
    );
  }

  /// At the exact minute when Android allows exact alarms (granted by
  /// default before Android 14; a setting after); otherwise Android may
  /// delay it a few minutes to save battery, which beats not showing it.
  Future<AndroidScheduleMode> _androidMode() async =>
      (await _android?.canScheduleExactNotifications() ?? false)
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

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
