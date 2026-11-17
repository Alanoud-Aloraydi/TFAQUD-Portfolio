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
    _ => null,
  };
}
