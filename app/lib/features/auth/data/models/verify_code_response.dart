/// The answer of POST /api/v1/auth/verify-code (docs/api-contracts.md, section
/// 5). Only the fields the app uses are read.
class VerifyCodeResponse {
  const VerifyCodeResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.profileComplete,
  });

  final String accessToken;
  final String refreshToken;

  /// False until the user has saved the name page, even for a user who signed
  /// in before. The app shows the name page while it is false.
  final bool profileComplete;

  /// Throws a [FormatException] when the body is not the expected shape, so the
  /// repository reports a failure instead of crashing.
  factory VerifyCodeResponse.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('verify-code answered without an object.');
    }
    final Object? access = json['access_token'];
    final Object? refresh = json['refresh_token'];
    final Object? user = json['user'];
    final Object? complete = user is Map ? user['profile_complete'] : null;
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
