import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Routes of the Flask API (backend/app/auth/routes.py, backend/app/health.py).
class ApiEndpoints {
  ApiEndpoints._();

  /// Prefix shared by every route of the API.
  static const String prefix = '/api/v1';

  /// Server address from `API_BASE_URL` in `.env`, followed by [prefix].
  static String get baseUrl {
    final String? host = dotenv.env['API_BASE_URL'];
    if (host == null || host.isEmpty) {
      throw StateError('API_BASE_URL is not set in .env');
    }
    final String trimmed =
        host.endsWith('/') ? host.substring(0, host.length - 1) : host;
    return '$trimmed$prefix';
  }

  static const String health = '/health';
  static const String refreshToken = '/auth/refresh';
  static const String signOut = '/auth/sign-out';
  static const String session = '/auth/session';

  /// Routes that never carry the access token.
  static const Set<String> withoutAccessToken = <String>{health, refreshToken};
}
