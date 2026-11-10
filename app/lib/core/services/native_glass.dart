import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Whether this iPhone draws Apple's own Liquid Glass (iOS 26 or later).
/// Read once at start-up by `setup()`; false on the web, on other platforms
/// and in tests, where the Flutter glass is used instead.
abstract class NativeGlass {
  NativeGlass._();

  static bool _isSupported = false;

  /// True on an iPhone with iOS 26 or later.
  static bool get isSupported => _isSupported;

  static Future<void> detect() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final IosDeviceInfo ios = await DeviceInfoPlugin().iosInfo;
      final int major = int.tryParse(ios.systemVersion.split('.').first) ?? 0;
      _isSupported = major >= 26;
    } on Exception catch (error) {
      // An unknown version keeps the Flutter glass, which works everywhere.
      debugPrint('NativeGlass.detect failed: $error');
      _isSupported = false;
    }
  }
}
