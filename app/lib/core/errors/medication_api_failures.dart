import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/network/api_error_body.dart';

/// What the medication endpoints refuse, each in the words its screen says.
/// Null when [code] is not a medication code.
Failure? medicationApiFailure(String? code) {
  return switch (code) {
    ApiErrorCodes.medicationPeriodConflict => const ConflictFailure(
      'medications.period_conflict',
    ),
    ApiErrorCodes.medicationVersionConflict => const ConflictFailure(
      'medications.version_conflict',
    ),
    ApiErrorCodes.medicationDiscontinued => const ConflictFailure(
      'medications.already_discontinued',
    ),
    ApiErrorCodes.medicationRevisionDate => const ValidationFailure(
      'medications.revision_date',
    ),
    ApiErrorCodes.medicationStartInPast => const ValidationFailure(
      'medications.start_in_past',
    ),
    ApiErrorCodes.doseRecordConflict => const ConflictFailure(
      'medications.dose_record_conflict',
    ),
    ApiErrorCodes.futureDoseRecord => const ValidationFailure(
      'medications.future_dose',
    ),
    ApiErrorCodes.futureTakenTime => const ValidationFailure(
      'medications.future_taken_time',
    ),
    ApiErrorCodes.doseTooOld => const ValidationFailure(
      'medications.dose_too_old',
    ),
    _ => null,
  };
}
