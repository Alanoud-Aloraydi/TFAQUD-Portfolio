import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges the iOS transparency preference, which MediaQuery does not expose.
abstract class AppAccessibility {
  static const channel = MethodChannel('tafaqod/accessibility');
  static final reduceTransparency = ValueNotifier<bool>(false);

  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'reduceTransparencyChanged' &&
          call.arguments is bool) {
        reduceTransparency.value = call.arguments as bool;
      }
    });
    reduceTransparency.value =
        await channel.invokeMethod<bool>('reduceTransparency') ?? false;
  }
}
