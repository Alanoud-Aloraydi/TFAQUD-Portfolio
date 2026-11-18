import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
