/// Account state shared by verification and session restoration responses.
class AccountStatusResponse {
  const AccountStatusResponse({
    required this.profileComplete,
    required this.appMode,
  });

  final bool profileComplete;
  final String? appMode;

  factory AccountStatusResponse.fromJson(Object? json) {
    if (json is! Map || json['profile_complete'] is! bool) {
      throw const FormatException('Missing account profile state.');
    }
    final Object? mode = json['app_mode'];
    if (mode != null && mode != 'detailed' && mode != 'simplified') {
      throw const FormatException('Invalid account mode.');
    }
    return AccountStatusResponse(
      profileComplete: json['profile_complete'] as bool,
      appMode: mode as String?,
    );
  }
}
