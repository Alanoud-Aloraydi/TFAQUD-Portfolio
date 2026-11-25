import 'package:app/core/errors/failure.dart';
import 'package:app/core/reminders/task_snooze.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading_draft.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/repositories/simplified_reminders.dart';
import 'package:app/features/simplified_mode/domain/usecases/result_attempt.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:multiple_result/multiple_result.dart';

/// The phone's reminders and calendar copy, kept for the simplified mode.
abstract class SimplifiedReminding {
  SimplifiedReminding(this._reminders);

  final SimplifiedReminders _reminders;

  /// Keeps the phone's reminders, and the calendar copy the person chose,
  /// set for [day]'s circle, as the detailed home does for its circles.
  Future<void> keepReminding(SimplifiedDay day) => _reminders.keep(day);

  /// Reads the week of reminders again: the app came back to the front.
  Future<void> refreshReminders() => _reminders.refresh();

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
    SimplifiedReminders reminders,
  ) : super(measurements, reminders);

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

/// The patient's readings: the recent ones, and saving a new one.
abstract class SimplifiedMeasuring extends SimplifiedReminding {
  SimplifiedMeasuring(this._measurements, SimplifiedReminders reminders)
    : super(reminders);

  final MeasurementsUseCase _measurements;

  /// The patient's last readings, newest first, over the past [days]: what
  /// they measured recently, so a reading can be seen beside the ones
  /// before it. Both kinds come back; the screen shows the kind it is on.
  Future<List<MeasurementReading>> recentReadings(
    String circleId,
    DateTime now, {
    int days = 7,
  }) async {
    final List<MeasurementReading> all = await _measurements.readings(
      circleId,
      addDays(now, -days),
      now,
    );
    return <MeasurementReading>[
      for (final MeasurementReading reading in all)
        if (reading.valueOne != null) reading,
    ]..sort(
      (MeasurementReading a, MeasurementReading b) =>
          (b.measuredAt ?? b.recordedAt).compareTo(
            a.measuredAt ?? a.recordedAt,
          ),
    );
  }

  /// Saves a reading: against [occurrence] when the patient opened it from
  /// that task, else as a free reading. A recorded task's snooze goes with
  /// the reminders' next reading.
  Future<Result<MeasurementReading, Failure>> recordMeasurement(
    String circleId,
    MeasurementReadingDraft draft, {
    MeasurementOccurrence? occurrence,
  }) => attemptResult(
    () => _measurements.record(circleId, draft, occurrence: occurrence),
  );
}
