import 'package:app/app/services/calendar_sync.dart';
import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/repositories/simplified_reminders.dart';
import 'package:flutter/foundation.dart' show ValueListenable;

/// The simplified mode's reminders on the app's reminder and calendar
/// services: the patient's one circle, kept the way the detailed home keeps
/// its circles.
class SimplifiedRemindersImpl implements SimplifiedReminders {
  SimplifiedRemindersImpl(this._reminders, this._calendar);

  final DoseReminders _reminders;
  final CalendarSync _calendar;

  @override
  Future<void> keep(SimplifiedDay day) {
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

  @override
  Future<void> refresh() => (_reminders.refresh(), _calendar.refresh()).wait;

  @override
  Future<void> snoozeDose(
    String circleId,
    DoseOccurrence dose,
    Duration after,
  ) => _reminders.snoozeDose(circleId, dose, after);

  @override
  Future<void> snoozeMeasurement(
    String circleId,
    MeasurementOccurrence measurement,
    Duration after,
  ) => _reminders.snoozeMeasurement(circleId, measurement, after);

  @override
  Future<bool> snoozeTap(String tap) => _reminders.snoozeTap(tap);

  @override
  ValueListenable<Map<String, TaskSnooze>> get snoozes => _reminders.snoozes;
}
