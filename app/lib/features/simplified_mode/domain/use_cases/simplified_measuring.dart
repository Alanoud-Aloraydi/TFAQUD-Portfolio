import 'package:app/core/errors/failure.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/domain/measurement_reading_draft.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/simplified_mode/domain/use_cases/result_attempt.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_reminding.dart';
import 'package:multiple_result/multiple_result.dart';

/// The patient's readings: the recent ones, and saving a new one.
abstract class SimplifiedMeasuring extends SimplifiedReminding {
  SimplifiedMeasuring(
    this._measurements,
    DoseReminders reminders,
    CalendarSync calendar,
  ) : super(reminders, calendar);

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
