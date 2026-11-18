import 'package:app/core/network/auth_endpoints.dart';
import 'package:app/core/network/circle_endpoints.dart';
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
