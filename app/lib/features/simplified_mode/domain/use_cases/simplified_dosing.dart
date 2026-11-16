import 'package:app/core/errors/failure.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/simplified_mode/domain/use_cases/simplified_measuring.dart';
import 'package:multiple_result/multiple_result.dart';

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

  /// «ما أخذتها»: the dose is written as skipped, with [reason] when the
  /// patient named one. The same record the detailed mode writes, so the
  /// family sees why in the log.
  Future<Result<DoseRecord, Failure>> skipDose(
    String circleId,
    DoseOccurrence dose,
    DoseSkipReason? reason,
  ) => _medications.recordDose(
    circleId,
    dose,
    DoseRecordDraft(
      outcome: DoseOutcome.skipped,
      skipReasonCode: reason?.apiValue,
    ),
  );
}
