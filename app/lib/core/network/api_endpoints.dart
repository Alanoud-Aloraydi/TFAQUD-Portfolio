import 'package:app/core/network/auth_interceptor.dart';
import 'package:app/core/network/circle_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// The Flask API: its address, the routes shared by the whole app
/// (backend/app/health.py, the home summary) and the routes that never
/// carry the access token. Each area's routes have their own class, such as
/// [AuthEndpoints] and [CircleEndpoints].
class ApiEndpoints {
  ApiEndpoints._();

  /// Prefix shared by every route of the API.
  static const String prefix = '/api/v1';

  /// Server address from a build override or `.env`, followed by [prefix].
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    final host = (override.isNotEmpty ? override : dotenv.env['API_BASE_URL'])
        ?.trim();
    if (host == null || host.isEmpty) {
      throw StateError('API_BASE_URL is not set in .env');
    }
    final String trimmed = host.endsWith('/')
        ? host.substring(0, host.length - 1)
        : host;
    return '$trimmed$prefix';
  }

  static const String health = '/health';
  static const String home = '/home';

  /// Routes that never carry the access token.
  static const Set<String> withoutAccessToken = <String>{
    health,
    AuthEndpoints.refreshToken,
    AuthEndpoints.requestCode,
    AuthEndpoints.verifyCode,
  };
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

/// Options shared by the main client and the interceptor's own client.
BaseOptions buildApiOptions() {
  return BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: const <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
}
