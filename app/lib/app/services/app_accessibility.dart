import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the glass (`GlassPreferences`) is drawn as opaque surfaces: the
/// iOS Reduce Transparency setting, which MediaQuery does not expose, and on
/// Android, which has no such setting, the phone's graphics.
abstract class AppAccessibility {
  static const channel = MethodChannel('tafaqod/accessibility');

  /// True with Reduce Transparency on (iOS), or on a phone too old for a
  /// smooth live blur (Android, [blurIsCostly]).
  static final reduceTransparency = ValueNotifier<bool>(false);

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final AndroidDeviceInfo android = await DeviceInfoPlugin().androidInfo;
        reduceTransparency.value = blurIsCostly(android.version.sdkInt);
      } on Exception catch (error) {
        // An unknown version keeps the glass, as on a recent phone.
        debugPrint('AppAccessibility.initialize failed: $error');
      }
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'reduceTransparencyChanged' &&
          call.arguments is bool) {
        reduceTransparency.value = call.arguments as bool;
      }
    });
    reduceTransparency.value =
        await channel.invokeMethod<bool>('reduceTransparency') ?? false;
  }

  /// Whether an Android phone on API [sdkInt] draws the glass opaque.
  ///
  /// Below Android 10 (API 29) Flutter cannot draw with Vulkan, and the
  /// GPUs of those phones redraw a background blur under every bar and
  /// button on each scrolled frame slowly enough to stutter; the opaque
  /// surface looks the same as with Reduce Transparency on an iPhone.
  @visibleForTesting
  static bool blurIsCostly(int sdkInt) => sdkInt < 29;
}
