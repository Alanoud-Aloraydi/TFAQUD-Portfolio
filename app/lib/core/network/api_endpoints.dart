import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Routes of the Flask API (backend/app/auth/routes.py,
/// backend/app/users/routes.py, backend/app/health.py).
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
  static const String refreshToken = '/auth/refresh';
  static const String signOut = '/auth/sign-out';
  static const String session = '/auth/session';
  static const String requestCode = '/auth/request-code';
  static const String verifyCode = '/auth/verify-code';
  static const String profile = '/accounts/me/profile';

  static String medicationPlans(String circleId) =>
      '/circles/$circleId/medication-plans';

  static String medicationPlan(String circleId, String planId) =>
      '${medicationPlans(circleId)}/$planId';

  static String discontinueMedication(String circleId, String planId) =>
      '${medicationPlan(circleId, planId)}/discontinue';

  static String medicationOccurrences(String circleId) =>
      '/circles/$circleId/medication-occurrences';

  static String medicationDoseRecord(
    String circleId,
    String scheduleId,
    String scheduledOn,
  ) =>
      '/circles/$circleId/medication-dose-records/'
      '$scheduleId/$scheduledOn';

  /// Routes that never carry the access token.
  static const Set<String> withoutAccessToken = <String>{
    health,
    refreshToken,
    requestCode,
    verifyCode,
  };
}
