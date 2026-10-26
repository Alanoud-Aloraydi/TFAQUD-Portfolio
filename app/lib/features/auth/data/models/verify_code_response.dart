import 'package:app/features/auth/data/models/account_status_response.dart';

/// Tokens and profile state returned by POST /api/v1/auth/verify-code.
class VerifyCodeResponse {
  const VerifyCodeResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.profileComplete,
    this.appMode,
  });

  final String accessToken;
  final String refreshToken;

  /// Whether the account has all required profile names.
  final bool profileComplete;
  final String? appMode;

  /// Parses the API response or throws [FormatException] for invalid fields.
  factory VerifyCodeResponse.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('verify-code answered without an object.');
    }
    final Object? access = json['access_token'];
    final Object? refresh = json['refresh_token'];
    final AccountStatusResponse account = AccountStatusResponse.fromJson(
      json['account'],
    );
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty) {
      throw const FormatException('verify-code answered without its fields.');
    }
    return VerifyCodeResponse(
      accessToken: access,
      refreshToken: refresh,
      profileComplete: account.profileComplete,
      appMode: account.appMode,
    );
  }
}
