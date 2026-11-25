import 'package:app/core/errors/appointment_api_failures.dart';
import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/generic_failures.dart';
import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/network/api_error_body.dart';
import 'package:dio/dio.dart';

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
