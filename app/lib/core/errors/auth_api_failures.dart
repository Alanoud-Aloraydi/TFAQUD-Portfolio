import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/invalid_birth_date_failure.dart';
import 'package:app/core/errors/network_failures.dart';
import 'package:app/core/network/api_error_body.dart';

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
    ApiErrorCodes.dataConflict => const ConflictFailure(),
    ApiErrorCodes.internalError => const ServerFailure(),
    _ => null,
  };
}
