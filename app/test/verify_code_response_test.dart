import 'package:app/features/auth/data/models/verify_code_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Map<String, Object?> valid = <String, Object?>{
    'access_token': 'access',
    'refresh_token': 'refresh',
    'account': <String, Object?>{'profile_complete': true},
  };

  test('reads tokens and a completed account profile', () {
    final VerifyCodeResponse result = VerifyCodeResponse.fromJson(valid);
    expect(result.accessToken, 'access');
    expect(result.refreshToken, 'refresh');
    expect(result.profileComplete, isTrue);
  });

  test('reads an incomplete account profile', () {
    final VerifyCodeResponse result = VerifyCodeResponse.fromJson(
      <String, Object?>{
        ...valid,
        'account': <String, Object?>{'profile_complete': false},
      },
    );
    expect(result.profileComplete, isFalse);
  });

  final Map<String, Object?> invalid = <String, Object?>{
    'null body': null,
    'list body': <Object?>[],
    'missing fields': <String, Object?>{},
    'empty access token': <String, Object?>{...valid, 'access_token': ''},
    'invalid profile flag': <String, Object?>{
      ...valid,
      'account': <String, Object?>{'profile_complete': 'true'},
    },
    'old user field': <String, Object?>{
      'access_token': 'access',
      'refresh_token': 'refresh',
      'user': <String, Object?>{'profile_complete': true},
    },
  };

  for (final MapEntry<String, Object?> entry in invalid.entries) {
    test('rejects ${entry.key}', () {
      expect(
        () => VerifyCodeResponse.fromJson(entry.value),
        throwsFormatException,
      );
    });
  }
}
