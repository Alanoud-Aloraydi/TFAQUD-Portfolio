import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';

/// The app's own notification sound, a soft two-note chime; the server's
/// pushes name the same file (`sender.py`). iOS finds it in `Library/Sounds`
/// once [installNotificationSound] copies it there (a Flutter asset is not
/// in the main bundle); until then iOS plays its default.
const String notificationSound = 'tafaqod_chime.wav';

/// Where the sound is in the app's assets.
const String notificationSoundAsset = 'assets/sounds/$notificationSound';

/// Copies [notificationSound] to `Library/Sounds`, where iOS finds it for
/// the reminders and the pushes. Done once; a failure leaves iOS's default
/// sound, which is still a sound.
Future<void> installNotificationSound() async {
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

/// The iOS action of a reminder that can be put off.
const String snoozeAction = 'snooze';

/// How long «ذكّرني لاحقًا» puts a reminder off from the notification.
const Duration notificationSnooze = Duration(minutes: 15);

/// What `PhoneNotifications.taps` gives for the snooze action: this, then
/// the reminder's own payload.
const String snoozeTapPrefix = 'snooze-action:';

/// Whether [tap] is the snooze action of a reminder, not a plain tap.
bool isSnoozeTap(String tap) => tap.startsWith(snoozeTapPrefix);

/// What `PhoneNotifications.taps` gives for a tapped server push: this,
/// its `kind`, then [pushItemSeparator] and the item (push_target.dart).
const String pushTapPrefix = 'push:';
const String pushItemSeparator = '#';

/// What `RemotePush.taps` gives for a reminder from the server: this, then
/// the tap one of the phone's own reminders would give (its payload, after
/// [snoozeTapPrefix] for «ذكّرني لاحقًا»), so both open the same task and
/// put off the same task.
const String serverReminderTapPrefix = 'server-reminder:';

/// What a tapped server push gives `PhoneNotifications.taps`: a reminder's
/// own tap, else [pushTapPrefix] and the push's text (push_target.dart).
String pushTap(String text) => text.startsWith(serverReminderTapPrefix)
    ? text.substring(serverReminderTapPrefix.length)
    : '$pushTapPrefix$text';

/// The server's `kind` of a tapped push, or null for a reminder's tap.
String? pushKind(String tap) => tap.startsWith(pushTapPrefix)
    ? tap.substring(pushTapPrefix.length).split(pushItemSeparator).first
    : null;

/// Whether the app runs on an iPhone or an Android phone; on the web and
/// desktop nothing is shown.
bool get runsOnPhone =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Whether this is an iPhone.
bool get runsOnIOS => defaultTargetPlatform == TargetPlatform.iOS;

/// The plugin's two sides.
extension NotificationPlatforms on FlutterLocalNotificationsPlugin {
  /// The plugin's iOS side; null on Android.
  IOSFlutterLocalNotificationsPlugin? get ios =>
      resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  /// The plugin's Android side; null on iOS.
  AndroidFlutterLocalNotificationsPlugin? get android =>
      resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
}
