import 'dart:async';

import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:flutter/foundation.dart' show listEquals;

/// Keeps what the phone does for the account's circles in step with the
/// home data: the reminders at the dose times, and the calendar events.
class ReminderSync {
  ReminderSync(this._reminders, this._calendar);

  final DoseReminders _reminders;
  final CalendarSync _calendar;

  /// The circles the phone was last set for, so choosing another circle
  /// does not read them all again.
  List<CareCircleSummary>? _circles;

  /// Sets the reminders and the calendar for [data]'s circles when their
  /// list changed since the last call.
  void onHome(HomeEntity data) {
    if (listEquals(_circles, data.circles)) return;
    _circles = data.circles;
    final circles = <ReminderCircle>[
      for (final CareCircleSummary circle in data.circles)
        ReminderCircle(
          id: circle.id,
          name: circle.name,
          viewerId: data.accountId,
          viewerIsPatient: circle.isPatient,
          timeZone: circle.timeZone,
        ),
    ];
    unawaited(_reminders.sync(circles));
    unawaited(_calendar.sync(circles));
  }

  /// The next week of reminders and events, and none for a dose marked
  /// meanwhile; for when the app comes back to the front.
  void refresh() {
    unawaited(_reminders.refresh());
    unawaited(_calendar.refresh());
  }
}
