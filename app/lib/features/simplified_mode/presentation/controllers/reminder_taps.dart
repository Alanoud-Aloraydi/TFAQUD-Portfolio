// ignore_for_file: prefer_initializing_formals
// A named parameter may not be private, so dart fix would break the build.
import 'dart:async';

import 'package:app/core/services/phone_notifications.dart';
import 'package:app/features/simplified_mode/domain/reminder_payload.dart';

/// Turns a tap on one of this mode's reminders — on the phone's lock
/// screen, in its list, or on the notification that started the app —
/// into the full-screen reminder.
///
/// A tap is kept until the day is read, and [openPending] is called again
/// on every change of the day, so a reading that failed or came back
/// slowly no longer loses it: that, and a launch tap that arrived after
/// the day was already read, were why a tapped reminder sometimes opened
/// nothing at all.
///
/// «ذكّرني لاحقًا» in the notification puts the task off and opens
/// nothing.
class ReminderTaps {
  /// [hasDay] says whether the day is read, [snooze] puts a task off from
  /// its notification, and [open] shows the full-screen reminder.
  ReminderTaps({
    required PhoneNotifications phone,
    required bool Function() hasDay,
    required Future<void> Function(String tap) snooze,
    required void Function(ReminderRequest request) open,
  }) : _hasDay = hasDay,
       _snooze = snooze,
       _open = open {
    // The launch tap is only queued: opening it here would navigate while
    // the screen is still being built. The first [openPending] shows it.
    final String? launch = phone.takeLaunchTap();
    if (launch != null) _queue(launch);
    _taps = phone.taps.listen(_onTap);
  }

  final bool Function() _hasDay;
  final Future<void> Function(String tap) _snooze;
  final void Function(ReminderRequest request) _open;
  late final StreamSubscription<String> _taps;

  /// The reminder tapped and not opened yet.
  ReminderRequest? _pending;

  void _onTap(String payload) {
    _queue(payload);
    openPending();
  }

  void _queue(String payload) {
    if (isSnoozeTap(payload)) {
      unawaited(_snooze(payload));
      return;
    }
    if (reminderRequest(payload) case final ReminderRequest request) {
      _pending = request;
    }
  }

  /// Opens the reminder that waited, once the day it belongs to is read.
  void openPending() {
    final ReminderRequest? request = _pending;
    if (request == null || !_hasDay()) return;
    _pending = null;
    _open(request);
  }

  void dispose() => unawaited(_taps.cancel());
}
