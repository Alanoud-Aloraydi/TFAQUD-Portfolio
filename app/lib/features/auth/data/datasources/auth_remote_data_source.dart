import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:injectable/injectable.dart';

/// The server refused the code because it is wrong.
class InvalidCodeException implements Exception {
  const InvalidCodeException();
}

abstract class BaseAuthRemoteDataSource {
  /// Asks the server to send the SMS code to [phone] (+9665XXXXXXXX).
  Future<void> requestCode(String phone);

  /// Checks the code. Returns true when the phone number had no account yet.
  /// Throws [InvalidCodeException] when the code is wrong.
  Future<bool> verifyCode(String phone, String code);

  /// POST /api/v1/auth/sign-out. The API answers 204 with an empty body.
  Future<void> signOut();
}

@LazySingleton(as: BaseAuthRemoteDataSource)
class AuthRemoteDataSource implements BaseAuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final DioClient _client;

  /// The two code endpoints are not built in the API yet, so [requestCode] and
  /// [verifyCode] answer on the phone. Replace their bodies with `_client.post`
  /// calls when the API has them; no other file changes.
  ///
  /// Test rules: the code 000000 is wrong; any other code is accepted.
  /// A phone number ending in 0 is a returning user; any other number is new.
  @override
  Future<void> requestCode(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<bool> verifyCode(String phone, String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (code == '000000') throw const InvalidCodeException();
    return !phone.endsWith('0');
  }

  @override
  Future<void> signOut() async {
    // No try/catch here: the repository turns any error into a Failure, once.
    // The interceptor adds the access token to this request.
    await _client.post(ApiEndpoints.signOut);
  }
}
