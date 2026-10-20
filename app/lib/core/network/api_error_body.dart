/// Error codes returned by the Flask API (backend/app/errors.py and
/// backend/app/auth).
abstract class ApiErrorCodes {
  ApiErrorCodes._();

  static const String missingToken = 'missing_token';
  static const String invalidToken = 'invalid_token';
  static const String accessTokenExpired = 'access_token_expired';
  static const String sessionRevoked = 'session_revoked';
  static const String invalidRefreshToken = 'invalid_refresh_token';
  static const String forbidden = 'forbidden';
  static const String notFound = 'not_found';
  static const String badRequest = 'bad_request';
  static const String invalidJson = 'invalid_json';
  static const String validationError = 'validation_error';
  static const String internalError = 'internal_error';
}

/// Reads `error.code` from a body of the form `{"error": {"code": ...}}`.
/// Returns null when the body does not have that shape.
String? apiErrorCode(Object? body) {
  if (body is Map) {
    final Object? error = body['error'];
    if (error is Map) {
      final Object? code = error['code'];
      if (code is String) return code;
    }
  }
  return null;
}
