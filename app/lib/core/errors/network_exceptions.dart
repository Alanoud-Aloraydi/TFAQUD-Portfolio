import 'dart:async';
import 'dart:io';

import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/errors/storage_failures.dart';
import 'package:app/core/network/api_error_body.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:dio/dio.dart';

/// Maps network failures to app error types.
class FailureExceptions {
  static Failure getException(Object error) {
    return switch (error) {
      DioException e => dioFailure(e),
      TokenStorageException _ => const StorageFailure('auth.storage_failed'),
      SocketException e => socketFailure(e),
      FormatException _ => const FormatFailure(),
      TimeoutException _ => const TimeoutFailure(),
      _ => const UnknownFailure(),
    };
  }
}

/// What a Dio error means to the app, by its kind.
Failure dioFailure(DioException error) {
  if (error.error is TokenStorageException) {
    return const StorageFailure('auth.storage_failed');
  }
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const TimeoutFailure(),
    DioExceptionType.connectionError => const NetworkFailure(),
    DioExceptionType.cancel => const CancelledFailure(),
    DioExceptionType.badResponse => responseFailure(error.response),
    _ => const UnknownFailure(),
  };
}

/// A socket says what went wrong in its message only, so the message is what
/// is read: no address and no route are the phone's own network, a refused
/// connection is the server.
Failure socketFailure(SocketException error) {
  final String message = error.message.toLowerCase();

  if (message.contains('failed host lookup') ||
      message.contains('network is unreachable') ||
      message.contains('no address associated')) {
    return const NetworkFailure();
  }
  if (message.contains('connection refused')) {
    return const ServerFailure();
  }
  if (message.contains('timed out')) {
    return const TimeoutFailure();
  }

  return const NetworkFailure();
}

class ServerFailure extends Failure {
  const ServerFailure([super.messageKey = 'error.server']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.messageKey = 'error.network']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.messageKey = 'error.timeout']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.messageKey = 'error.resource_not_found']);
}

/// The API code takes precedence; the status code is the fallback for
/// responses that do not have the API error body (for example from a proxy).
Failure responseFailure(Response<dynamic>? response) {
  final String? code = apiErrorCode(response?.data);
  return authApiFailure(code) ??
      medicationApiFailure(code) ??
      measurementApiFailure(code) ??
      appointmentApiFailure(code) ??
      statusCodeFailure(response?.statusCode);
}

/// The fallback when the response carries no API error code.
Failure statusCodeFailure(int? code) {
  return switch (code) {
    400 || 422 => const ValidationFailure(),
    409 => const ConflictFailure(),
    401 => const UnauthorizedFailure(),
    403 => const ForbiddenFailure(),
    404 => const NotFoundFailure(),
    _ when code != null && code >= 500 => const ServerFailure(),
    _ => const UnknownFailure(),
  };
}

/// The codes that belong to no one feature: the session, the permission, the
/// shape of the request, and the server's own trouble. Null when [code] is
/// a feature's own.
Failure? authApiFailure(String? code) {
  return switch (code) {
    ApiErrorCodes.accessTokenExpired ||
    ApiErrorCodes.sessionRevoked ||
    ApiErrorCodes.invalidRefreshToken => const SessionExpiredFailure(),
    ApiErrorCodes.missingToken ||
    ApiErrorCodes.invalidToken => const UnauthorizedFailure(),
    ApiErrorCodes.forbidden => const ForbiddenFailure(),
    ApiErrorCodes.notFound => const NotFoundFailure(),
    ApiErrorCodes.validationError ||
    ApiErrorCodes.badRequest ||
    ApiErrorCodes.invalidJson => const ValidationFailure(),
    ApiErrorCodes.invalidBirthDate => const InvalidBirthDateFailure(),
    ApiErrorCodes.tooYoung => const TooYoungFailure(),
    ApiErrorCodes.dataConflict => const ConflictFailure(),
    ApiErrorCodes.internalError => const ServerFailure(),
    _ => null,
  };
}

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

class UnknownFailure extends Failure {
  const UnknownFailure([super.messageKey = 'error.unknown']);
}

class CancelledFailure extends Failure {
  const CancelledFailure([super.messageKey = 'error.unknown']);
}
