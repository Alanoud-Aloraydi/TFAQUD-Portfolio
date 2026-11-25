// ignore_for_file: prefer_initializing_formals
// A named parameter may not be private, so dart fix would break the build.
import 'dart:async';

import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/push_target.dart';
import 'package:app/app/services/reminders/reminder_payload_parts.dart';
import 'package:app/app/services/reminders/tapped_item.dart';
import 'package:app/core/reminders/reminder_payloads.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';

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

/// What a tapped reminder (or snooze) asks about, so the simplified mode
/// opens its full-screen reminder; null for the note to open the app and
/// for anything that is not a reminder. A server push about a dose or a
/// reading put off or missed, or a visit missed, opens that task the same
/// way.
ReminderRequest? reminderRequest(String payload) {
  if (pushKind(payload) case final String kind) {
    return _pushRequest(kind, pushTapItem(payload));
  }
  if (reminderCircleId(payload) == null) return null;
  final TodayTaskKind? kind =
      payload.startsWith(doseReminderPayload) ||
          payload.startsWith(doseSnoozePayload)
      ? TodayTaskKind.medication
      : payload.startsWith(measurementReminderPayload) ||
            payload.startsWith(measurementSnoozePayload)
      ? TodayTaskKind.measurement
      : payload.startsWith(appointmentReminderPayload)
      ? TodayTaskKind.appointment
      : null;
  if (kind == null) return null;
  return ReminderRequest(kind, taskKey: tappedItemKey(payload));
}

/// A missed visit opens its reminder too: «حضرت» can still be said.
ReminderRequest? _pushRequest(String kind, String? item) => switch (kind) {
  'dose_missed' ||
  'dose_snoozed' => ReminderRequest(TodayTaskKind.medication, taskKey: item),
  'measurement_missed' || 'measurement_snoozed' => ReminderRequest(
    TodayTaskKind.measurement,
    taskKey: item,
  ),
  'appointment_missed' => ReminderRequest(
    TodayTaskKind.appointment,
    taskKey: item,
  ),
  _ => null,
};
