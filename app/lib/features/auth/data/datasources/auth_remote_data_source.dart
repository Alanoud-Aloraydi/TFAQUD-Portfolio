import 'dart:math';

import 'package:app/core/network/auth_interceptor.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/auth/data/models/account_status_response.dart';
import 'package:app/features/auth/data/models/verify_code_response.dart';
import 'package:app/features/auth/domain/entities/code_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sends auth requests to the API.
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

/// Sends base auth requests to the API.
abstract class BaseAuthRemoteDataSource {
  /// Requests an OTP for [phone] and returns its verification identifier and
  /// the wait before the next code. An existing [verificationId] resends
  /// within the same request.
  Future<CodeRequest> requestCode(String phone, {String? verificationId});

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

/// A random id for this install of the app, kept in the secure storage.
///
/// The app sends it as `X-Device-Id` when it asks for a sign-in code: the
/// server counts the codes one phone asks for, so one phone cannot send
/// codes to many numbers. It names nobody and changes after a reinstall.
class DeviceId {
  DeviceId(this._storage);

  final FlutterSecureStorage _storage;

  static const String _key = 'device_id';

  String? _id;

  /// The id, made the first time. Without the storage it lives until the
  /// app closes.
  Future<String> read() async {
    final String? known = _id;
    if (known != null) return known;
    try {
      final String? stored = await _storage.read(key: _key);
      if (stored != null && stored.isNotEmpty) return _id = stored;
    } on Exception {
      return _id = _make();
    }
    final String made = _make();
    try {
      await _storage.write(key: _key, value: made);
    } on Exception {
      // Kept in memory only.
    }
    return _id = made;
  }

  /// 32 random hex digits.
  static String _make() {
    final Random random = Random.secure();
    return List<String>.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
