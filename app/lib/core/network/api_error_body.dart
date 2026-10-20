import 'package:dio/dio.dart' show DioException;

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

  // Sign-in (backend/app/auth/sign_in.py) and the profile.
  static const String verificationNotFound = 'verification_not_found';
  static const String userNotFound = 'user_not_found';
  static const String invalidCode = 'invalid_code';
  static const String codeExpired = 'code_expired';
  static const String codeAlreadyUsed = 'code_already_used';
  static const String tooManyAttempts = 'too_many_attempts';
  static const String tooManyCodes = 'too_many_codes';
  static const String smsUnavailable = 'sms_unavailable';
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

/// The API error code inside [error], when [error] is a [DioException] whose
/// response has the API error body. Returns null for any other error.
String? apiErrorCodeOf(Object error) =>
    error is DioException ? apiErrorCode(error.response?.data) : null;
