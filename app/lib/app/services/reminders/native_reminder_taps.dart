import 'package:flutter/services.dart';

/// The app's reminders tapped on iOS, as its delegate keeps them
/// (AppDelegate.swift): from the first moment of a launch, so a reminder
/// that opens the closed app is not lost while Flutter's plugins are still
/// being registered.
class NativeReminderTaps {
  const NativeReminderTaps([
    this._channel = const MethodChannel('tafaqod/reminder_taps'),
  ]);

  final MethodChannel _channel;

  /// Gives [onTap] each tap: its payload, and the action pressed (empty for
  /// the reminder itself). The ones kept before come first.
  Future<void> listen(
    void Function(String payload, String action) onTap,
  ) async {
    void give(Object? tap) {
      if (tap case {
        'payload': final String payload,
        'action': final String action,
      }) {
        onTap(payload, action);
      }
    }

    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'tap') give(call.arguments);
    });
    try {
      final List<Object?> kept =
          await _channel.invokeListMethod<Object?>('listen') ?? <Object?>[];
      kept.forEach(give);
    } on MissingPluginException {
      // A build without the native side: its taps come from the plugin.
    }
  }
}
