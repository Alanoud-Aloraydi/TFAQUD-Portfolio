/// Contract for storing the session tokens. Widgets and Cubits depend on
/// this interface, never on FlutterSecureStorage directly.
abstract interface class TokenStorage {
  int get revision;
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  /// Replaces the access token only. The refresh endpoint returns a new access
  /// token and keeps the refresh token.
  Future<void> saveAccessToken(String accessToken, {int? expectedRevision});

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> clear({int? expectedRevision});
}
