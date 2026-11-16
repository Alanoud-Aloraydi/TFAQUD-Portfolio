import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/data_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/generic_failures.dart';
import 'package:app/core/errors/network_failures.dart';

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
