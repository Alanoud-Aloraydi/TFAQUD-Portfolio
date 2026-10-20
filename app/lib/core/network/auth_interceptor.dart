import 'dart:async';

import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/api_error_body.dart';
import 'package:app/core/network/api_options.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';

/// Attaches the access token and renews it when the API reports it expired.
///
/// Contract with the backend (backend/app/auth):
/// - `Authorization: Bearer <access token>` on every route except `/health`
///   and `/auth/refresh`.
/// - `POST /auth/refresh` takes `{"refresh_token": ...}` and returns a new
///   access token only; the refresh token is not rotated.
/// - Errors have the form `{"error": {"code": ...}}`.
///
/// Error handling is queued, so concurrent 401 responses lead to one renewal:
/// a request whose token differs from the stored one was queued behind a
/// renewal and is only retried. The renewal and the retry use a separate client
/// without this interceptor, which avoids re-entering the queue. The pattern
/// follows the Dio example `queued_interceptor_crsftoken.dart`; Cookbook III
/// ch. 9 does not cover token renewal.
@lazySingleton
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._tokens);

  static const String _retriedKey = 'auth_retried';

  /// 401 codes after which the stored tokens can no longer be used.
  static const Set<String> _sessionEndingCodes = <String>{
    ApiErrorCodes.missingToken,
    ApiErrorCodes.invalidToken,
    ApiErrorCodes.sessionRevoked,
    ApiErrorCodes.invalidRefreshToken,
  };

  final TokenStorage _tokens;
  final StreamController<void> _sessionEnded =
      StreamController<void>.broadcast();
  Dio? _plainDio;

  /// Emits when the tokens were cleared because the session can no longer be
  /// renewed. The user has to sign in again.
  Stream<void> get sessionEnded => _sessionEnded.stream;

  Dio get _plain => _plainDio ??= Dio(buildApiOptions());

  @visibleForTesting
  set plainDio(Dio dio) => _plainDio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!ApiEndpoints.withoutAccessToken.contains(options.path)) {
      final String? token = await _tokens.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions request = err.requestOptions;
    final bool candidate = err.response?.statusCode == 401 &&
        request.path != ApiEndpoints.refreshToken &&
        request.extra[_retriedKey] != true;
    if (!candidate) {
      handler.next(err);
      return;
    }

    final String? code = apiErrorCode(err.response?.data);
    if (code == ApiErrorCodes.accessTokenExpired) {
      final String? token;
      try {
        token = await _renewedAccessToken(request);
      } on DioException {
        // The renewal could not be attempted (for example no connection).
        // The tokens are kept and the original error is reported.
        handler.next(err);
        return;
      }
      if (token == null) {
        await _endSession();
        handler.next(err);
        return;
      }
      await _retry(request, token, handler);
      return;
    }

    if (_sessionEndingCodes.contains(code)) {
      await _endSession();
    }
    handler.next(err);
  }

  /// Returns a usable access token, or null when the session cannot be renewed.
  /// Throws a [DioException] when the renewal request itself fails to complete.
  Future<String?> _renewedAccessToken(RequestOptions failed) async {
    final String? current = await _tokens.readAccessToken();
    // An earlier request in the queue may already have renewed the token.
    if (current != null &&
        current.isNotEmpty &&
        failed.headers['Authorization'] != 'Bearer $current') {
      return current;
    }

    final String? refresh = await _tokens.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return null;

    try {
      final Response<dynamic> response = await _plain.post<dynamic>(
        ApiEndpoints.refreshToken,
        data: <String, String>{'refresh_token': refresh},
      );
      final Object? body = response.data;
      final Object? token = body is Map ? body['access_token'] : null;
      if (token is! String || token.isEmpty) return null;
      await _tokens.saveAccessToken(token);
      return token;
    } on DioException catch (error) {
      // The API rejected the refresh token: the session is over.
      if (error.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<void> _retry(
    RequestOptions request,
    String token,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions retry = request.copyWith(
      headers: <String, dynamic>{
        ...request.headers,
        'Authorization': 'Bearer $token',
      },
      extra: <String, dynamic>{...request.extra, _retriedKey: true},
    );
    try {
      handler.resolve(await _plain.fetch<dynamic>(retry));
    } on DioException catch (error) {
      handler.reject(error);
    }
  }

  Future<void> _endSession() async {
    await _tokens.clear();
    if (!_sessionEnded.isClosed) _sessionEnded.add(null);
  }
}
