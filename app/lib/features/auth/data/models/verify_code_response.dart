/// Tokens and profile state returned by POST /api/v1/auth/verify-code.
class VerifyCodeResponse {
  const VerifyCodeResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.profileComplete,
  });

  final String accessToken;
  final String refreshToken;

  /// Whether the account has all required profile names.
  final bool profileComplete;

  /// Parses the API response or throws [FormatException] for invalid fields.
  factory VerifyCodeResponse.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('verify-code answered without an object.');
    }
    final Object? access = json['access_token'];
    final Object? refresh = json['refresh_token'];
    final Object? account = json['account'];
    final Object? complete = account is Map
        ? account['profile_complete']
        : null;
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty ||
        complete is! bool) {
      throw const FormatException('verify-code answered without its fields.');
    }
    return VerifyCodeResponse(
      accessToken: access,
      refreshToken: refresh,
      profileComplete: complete,
    );
  }
}
