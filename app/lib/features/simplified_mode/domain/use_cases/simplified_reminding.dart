import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

/// The phone's reminders and calendar copy, kept for the simplified mode.
abstract class SimplifiedReminding {
  SimplifiedReminding(this._reminders, this._calendar);

  final DoseReminders _reminders;
  final CalendarSync _calendar;

  /// Keeps the phone's reminders, and the calendar copy the person chose,
  /// set for [day]'s circle, as the detailed home does for its circles.
  Future<void> keepReminding(SimplifiedDay day) {
    final List<ReminderCircle> circles = <ReminderCircle>[
      ReminderCircle(
        id: day.circleId,
        name: day.circleName,
        viewerId: day.accountId,
        viewerIsPatient: day.isPatient,
        timeZone: day.timeZone,
      ),
    ];
    return (_reminders.sync(circles), _calendar.sync(circles)).wait;
  }

  /// Reads the week of reminders again: the app came back to the front.
  Future<void> refreshReminders() =>
      (_reminders.refresh(), _calendar.refresh()).wait;

  /// «ذكّرني لاحقًا» on [task] of [circleId]: the same as the detailed
  /// mode's, so its reminder, its card and its calendar copy move to
  /// [after] from now.
  Future<void> snooze(String circleId, TodayTask task, Duration after) async {
    if (task.dose case final DoseOccurrence dose) {
      await _reminders.snoozeDose(circleId, dose, after);
    } else if (task.measurement case final MeasurementOccurrence measurement) {
      await _reminders.snoozeMeasurement(circleId, measurement, after);
    }
  }

  /// «ذكّرني لاحقًا» pressed in a notification: its task comes again, as
  /// in the detailed mode. False when [tap] is not that button.
  Future<bool> snoozeFromNotification(String tap) => _reminders.snoozeTap(tap);

  /// The tasks put off, by [TodayTask.snoozeKey], until each comes again.
  ValueListenable<Map<String, TaskSnooze>> get snoozes => _reminders.snoozes;
}
