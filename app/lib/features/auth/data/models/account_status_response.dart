import 'package:app/features/circles/domain/circle_app_mode.dart';

/// Account state shared by verification and session restoration responses.
class AccountStatusResponse {
  const AccountStatusResponse({
    required this.profileComplete,
    this.appMode = CircleAppMode.detailed,
  });

  final bool profileComplete;

  /// The mode the account opens in; [CircleAppMode.detailed] when the server
  /// sends none (an account that never had a circle with a mode).
  final CircleAppMode appMode;

  /// Parses the `account` object, or throws [FormatException] when the
  /// profile flag or the mode is not what the API documents.
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
      appMode: CircleAppMode.parse(mode as String?),
    );
  }
}
