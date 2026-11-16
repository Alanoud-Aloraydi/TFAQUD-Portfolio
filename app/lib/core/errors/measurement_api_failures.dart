import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/network/api_error_body.dart';

/// What the measurement endpoints refuse, each in the words its screen says.
/// Null when [code] is not a measurement code.
Failure? measurementApiFailure(String? code) {
  return switch (code) {
    ApiErrorCodes.measurementActivePlanExists => const ConflictFailure(
      'measurements.active_plan_exists',
    ),
    ApiErrorCodes.measurementStartInPast => const ValidationFailure(
      'measurements.start_in_past',
    ),
    ApiErrorCodes.measurementPlanChanged => const ConflictFailure(
      'measurements.plan_changed',
    ),
    ApiErrorCodes.measurementEffectiveDate => const ValidationFailure(
      'measurements.effective_date',
    ),
    ApiErrorCodes.measurementRecordConflict => const ConflictFailure(
      'measurements.record_conflict',
    ),
    ApiErrorCodes.futureMeasurement => const ValidationFailure(
      'measurements.future_reading',
    ),
    ApiErrorCodes.futureMeasurementTask => const ValidationFailure(
      'measurements.future_task',
    ),
    ApiErrorCodes.measurementWithinTarget => const ValidationFailure(
      'measurements.no_follow_up',
    ),
    _ => null,
  };
}
