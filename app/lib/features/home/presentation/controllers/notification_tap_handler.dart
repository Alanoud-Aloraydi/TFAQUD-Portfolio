import 'dart:async';

import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:flutter/foundation.dart' show VoidCallback;

/// Turns a tap on a reminder of the phone into what the app does.
///
/// A reminder of a dose, a measurement or an appointment opens «اليوم» of
/// its circle, where each of them is; the note to open the app opens
/// «اليوم» as it is. A server push about an invitation or a request opens
/// the notifications page; any other push opens «اليوم» as it is.
/// «ذكّرني لاحقًا» sets the reminder again and stays. A tap
/// that arrives before the home data is ready (also the tap that launched
/// the app) waits for [onReady].
class NotificationTapHandler {
  /// [isReady] says whether the home data is ready, [openToday] shows
  /// «اليوم» after selecting [circleId] (when there is one), [openInbox]
  /// shows the notifications page, and [onSnoozed] tells the person the
  /// reminder was put off.
  NotificationTapHandler(
    PhoneNotifications phone,
    this._reminders, {
    required this._isReady,
    required this._openToday,
    required this._openInbox,
    required this._onSnoozed,
  }) {
    _pending = phone.takeLaunchTap();
    _taps = phone.taps.listen(_onTap);
  }

  final DoseReminders _reminders;
  final bool Function() _isReady;
  final void Function(String? circleId) _openToday;
  final VoidCallback _openInbox;
  final VoidCallback _onSnoozed;
  late final StreamSubscription<String> _taps;
  bool _disposed = false;

  /// A tap that came before the home data was ready.
  String? _pending;

  void _onTap(String payload) {
    if (isSnoozeTap(payload) || _isReady()) {
      _open(payload);
    } else {
      _pending = payload;
    }
  }

  /// The home data is ready: opens the tap that waited.
  void onReady() {
    final String? tap = _pending;
    if (tap != null) _open(tap);
  }

  void _open(String payload) {
    _pending = null;
    if (isSnoozeTap(payload)) {
      unawaited(_snooze(payload));
      return;
    }
    if (inboxPushKinds.contains(pushKind(payload))) {
      _openInbox();
      return;
    }
    _openToday(reminderCircleId(payload));
  }

  /// Puts a reminder off from its notification.
  Future<void> _snooze(String tap) async {
    final bool done = await _reminders.snoozeTap(tap);
    if (done && !_disposed) _onSnoozed();
  }

  /// Stops listening; a tap that is still waiting is dropped.
  void dispose() {
    _disposed = true;
    unawaited(_taps.cancel());
  }
}
