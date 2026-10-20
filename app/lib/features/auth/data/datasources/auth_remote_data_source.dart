import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/auth/data/models/verify_code_response.dart';
import 'package:injectable/injectable.dart';

abstract class BaseAuthRemoteDataSource {
  /// POST /api/v1/auth/request-code. Sends the SMS code to [phone]
  /// (+9665XXXXXXXX) and returns the verification id of the request.
  ///
  /// Pass the id of an earlier call as [verificationId] to send another SMS for
  /// the same request (a resend). Without it a new request starts.
  Future<String> requestCode(String phone, {String? verificationId});

  /// POST /api/v1/auth/verify-code. Returns the tokens and whether the profile
  /// is complete. A refused code is a DioException with a 4xx answer; the
  /// repository turns its API code into a Failure.
  Future<VerifyCodeResponse> verifyCode({
    required String verificationId,
    required String code,
  });

  /// POST /api/v1/auth/sign-out. The API answers 204 with an empty body.
  Future<void> signOut();

  /// GET /api/v1/auth/session. The API answers 200 while the session is
  /// valid. When the answer is a 401 that ends the session, the interceptor
  /// removes the tokens (and renews an expired access token first).
  Future<void> checkSession();
}

@LazySingleton(as: BaseAuthRemoteDataSource)
class AuthRemoteDataSource implements BaseAuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final DioClient _client;

  // No try/catch in this class: the repository turns any error into a Failure,
  // once. The interceptor does not add the access token to the two code calls
  // (ApiEndpoints.withoutAccessToken).

  @override
  Future<String> requestCode(String phone, {String? verificationId}) async {
    final response = await _client.post(
      ApiEndpoints.requestCode,
      data: <String, dynamic>{
        'phone': phone,
        'verification_id': ?verificationId,
      },
    );
    final Object? body = response.data;
    final Object? id = body is Map ? body['verification_id'] : null;
    if (id is! String || id.isEmpty) {
      throw const FormatException('request-code answered without an id.');
    }
    return id;
  }

  @override
  Future<VerifyCodeResponse> verifyCode({
    required String verificationId,
    required String code,
  }) async {
    final response = await _client.post(
      ApiEndpoints.verifyCode,
      data: <String, String>{'verification_id': verificationId, 'code': code},
    );
    return VerifyCodeResponse.fromJson(response.data);
  }

  @override
  Future<void> signOut() async {
    // The interceptor adds the access token to this request.
    await _client.post(ApiEndpoints.signOut);
  }

  @override
  Future<void> checkSession() async {
    await _client.get(ApiEndpoints.session);
  }
}
