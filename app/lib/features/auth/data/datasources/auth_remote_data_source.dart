import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/auth/data/models/account_status_response.dart';
import 'package:app/features/auth/data/models/verify_code_response.dart';
import 'package:injectable/injectable.dart';

abstract class BaseAuthRemoteDataSource {
  /// Requests an OTP for [phone] and returns its verification identifier.
  /// An existing [verificationId] resends within the same request.
  Future<String> requestCode(String phone, {String? verificationId});

  /// Verifies an OTP and returns the session tokens and profile state.
  Future<VerifyCodeResponse> verifyCode({
    required String verificationId,
    required String code,
  });

  /// Revokes the current session through POST /api/v1/auth/sign-out.
  Future<void> signOut();

  /// Checks the current session; token renewal is handled by the interceptor.
  Future<AccountStatusResponse> checkSession();
}

@LazySingleton(as: BaseAuthRemoteDataSource)
class AuthRemoteDataSource implements BaseAuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final DioClient _client;

  @override
  Future<String> requestCode(String phone, {String? verificationId}) async {
    final response = await _client.post(
      ApiEndpoints.requestCode,
      data: <String, dynamic>{
        'phone_number': phone,
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
    await _client.post(ApiEndpoints.signOut);
  }

  @override
  Future<AccountStatusResponse> checkSession() async {
    final response = await _client.get(ApiEndpoints.session);
    final Object? body = response.data;
    return AccountStatusResponse.fromJson(body is Map ? body['account'] : null);
  }
}
