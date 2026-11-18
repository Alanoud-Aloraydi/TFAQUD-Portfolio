import 'package:app/core/network/dio_client.dart';
import 'package:app/features/auth/data/datasources/base_auth_remote_data_source.dart';
import 'package:app/features/auth/data/datasources/device_id.dart';
import 'package:app/features/auth/data/models/account_status_response.dart';
import 'package:app/features/auth/data/models/verify_code_response.dart';
import 'package:app/features/auth/domain/entities/code_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/network/auth_endpoints.dart';

export 'package:app/features/auth/data/datasources/base_auth_remote_data_source.dart';

/// Sends auth requests to the API.
@LazySingleton(as: BaseAuthRemoteDataSource)
class AuthRemoteDataSource implements BaseAuthRemoteDataSource {
  AuthRemoteDataSource(this._client, FlutterSecureStorage storage)
    : _deviceId = DeviceId(storage);

  final DioClient _client;
  final DeviceId _deviceId;

  @override
  Future<CodeRequest> requestCode(
    String phone, {
    String? verificationId,
  }) async {
    final response = await _client.post(
      AuthEndpoints.requestCode,
      data: <String, dynamic>{
        'phone_number': phone,
        'verification_id': ?verificationId,
      },
      // The server counts the codes one phone asks for.
      options: Options(
        headers: <String, String>{'X-Device-Id': await _deviceId.read()},
      ),
    );
    final Object? body = response.data;
    final Object? id = body is Map ? body['verification_id'] : null;
    if (id is! String || id.isEmpty) {
      throw const FormatException('request-code answered without an id.');
    }
    final Object? wait = body is Map ? body['resend_after_seconds'] : null;
    return CodeRequest(
      verificationId: id,
      resendAfterSeconds: wait is int && wait > 0 ? wait : 0,
    );
  }

  @override
  Future<VerifyCodeResponse> verifyCode({
    required String verificationId,
    required String code,
  }) async {
    final response = await _client.post(
      AuthEndpoints.verifyCode,
      data: <String, String>{'verification_id': verificationId, 'code': code},
    );
    return VerifyCodeResponse.fromJson(response.data);
  }

  @override
  Future<void> signOut() async {
    await _client.post(AuthEndpoints.signOut);
  }

  @override
  Future<AccountStatusResponse> checkSession() async {
    final response = await _client.get(AuthEndpoints.session);
    final Object? body = response.data;
    return AccountStatusResponse.fromJson(body is Map ? body['account'] : null);
  }
}
