import 'package:app/app/services/calendar_sync.dart';
import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/usecases/simplified_measuring.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:multiple_result/multiple_result.dart';

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

  /// The tasks put off, by [TodayTaskSnoozeKey.snoozeKey], until each comes
  /// again.
  ValueListenable<Map<String, TaskSnooze>> get snoozes => _reminders.snoozes;
}

/// Writing the patient's doses as taken or skipped.
abstract class SimplifiedDosing extends SimplifiedMeasuring {
  SimplifiedDosing(
    this._medications,
    MeasurementsUseCase measurements,
    DoseReminders reminders,
    CalendarSync calendar,
  ) : super(measurements, reminders, calendar);

  final MedicationsUseCase _medications;

  /// Records [dose] as taken at [takenAt]. Its snooze goes with the
  /// reminders' next reading, which the record starts.
  Future<Result<DoseRecord, Failure>> takeDose(
    String circleId,
    DoseOccurrence dose,
    DateTime takenAt,
  ) => _medications.recordDose(
    circleId,
    dose,
    DoseRecordDraft(outcome: DoseOutcome.taken, takenAt: takenAt),
  );

  /// «لم آخذها»: the dose is written as skipped, with [reason] when the
  /// patient named one and the [note] written for «سبب آخر». The same
  /// record the detailed mode writes, so the family sees why in the log.
  Future<Result<DoseRecord, Failure>> skipDose(
    String circleId,
    DoseOccurrence dose,
    DoseSkipReason? reason, {
    String? note,
  }) => _medications.recordDose(
    circleId,
    dose,
    DoseRecordDraft(
      outcome: DoseOutcome.skipped,
      skipReasonCode: reason?.apiValue,
      skipReasonNote: note,
    ),
  );
}
