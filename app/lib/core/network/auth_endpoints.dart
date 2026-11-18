/// The sign-in routes of the API (backend/app/auth/routes.py): the code by
/// SMS, the session and its renewal.
abstract final class AuthEndpoints {
  static const String refreshToken = '/auth/refresh';
  static const String signOut = '/auth/sign-out';
  static const String session = '/auth/session';
  static const String requestCode = '/auth/request-code';
  static const String verifyCode = '/auth/verify-code';
}
