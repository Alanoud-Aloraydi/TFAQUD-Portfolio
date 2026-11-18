import 'dart:async';

import 'package:app/core/services/notifications/notification_taps.dart';

/// The taps on notifications, for the page that listens.
class TapInbox {
  final StreamController<String> _taps = StreamController<String>.broadcast();
  String? _launchTap;

  /// The payload of each notification tapped while a page listens.
  Stream<String> get taps => _taps.stream;

  /// Gives [tap] to the page that listens, or keeps it as the launch tap
  /// while none listens yet. A reminder or a push tapped while the app was
  /// closed arrives as soon as the app starts (on iOS, kept by the app's
  /// delegate: NativeReminderTaps), often before any page is built; the
  /// broadcast [taps] would drop it, and the reminder would open nothing.
  void deliver(String tap) {
    if (_taps.hasListener) {
      _taps.add(tap);
    } else {
      _launchTap = tap;
    }
  }

  /// Gives [deliver] the [payload] ([snoozeTapPrefix] first for [action]
  /// snooze); nothing without a payload.
  void deliverResponse(String? payload, String? action) {
    if (payload == null || payload.isEmpty) return;
    deliver(action == snoozeAction ? '$snoozeTapPrefix$payload' : payload);
  }

  /// The payload of a tap no page heard yet (the one that opened the
  /// app), once.
  String? takeLaunchTap() {
    final String? tap = _launchTap;
    _launchTap = null;
    return tap;
  }
}
