import 'package:dio/dio.dart' show DioException;

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

/// The `error.retry_after_seconds` of an API error inside [error], when the
/// server says how long to wait. Null otherwise.
int? apiRetryAfterOf(Object error) {
  if (error is! DioException) return null;
  final Object? body = error.response?.data;
  if (body is Map) {
    final Object? inner = body['error'];
    if (inner is Map) {
      final Object? seconds = inner['retry_after_seconds'];
      if (seconds is int && seconds > 0) return seconds;
    }
  }
  return null;
}
