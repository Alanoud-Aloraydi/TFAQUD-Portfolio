import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/network/api_error_body.dart';

/// What the appointment endpoints refuse, each in the words its screen says.
/// Null when [code] is not an appointment code.
Failure? appointmentApiFailure(String? code) {
  return switch (code) {
    ApiErrorCodes.appointmentTimeInPast => const ValidationFailure(
      'appointments.time_in_past',
    ),
    ApiErrorCodes.appointmentNotStarted => const ValidationFailure(
      'appointments.not_started',
    ),
    ApiErrorCodes.appointmentMissed => const ValidationFailure(
      'appointments.attend_closed',
    ),
    ApiErrorCodes.appointmentChanged => const ConflictFailure(
      'appointments.changed',
    ),
    ApiErrorCodes.appointmentAlreadyClosed => const ConflictFailure(
      'appointments.already_closed',
    ),
    ApiErrorCodes.appointmentInvalidCompanion => const ValidationFailure(
      'appointments.invalid_companion',
    ),
    ApiErrorCodes.appointmentInvalidAudio => const ValidationFailure(
      'appointments.invalid_audio',
    ),
    ApiErrorCodes.appointmentVisitNotCompleted => const ConflictFailure(
      'appointments.visit_not_completed',
    ),
    // «حضرت» stays while «ورقة الزيارة» has something in it.
    ApiErrorCodes.appointmentVisitFilled => const ConflictFailure(
      'appointments.outcome_locked',
    ),
    ApiErrorCodes.appointmentOutcomeClosed => const ValidationFailure(
      'appointments.outcome_closed',
    ),
    _ => null,
  };
}

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
