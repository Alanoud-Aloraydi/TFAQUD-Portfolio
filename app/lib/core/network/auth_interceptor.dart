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
/// Queued renewal shares credentials only within the originating session.
@lazySingleton
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._tokens);

  static const String _retriedKey = 'auth_retried';
  static const String _revisionKey = 'auth_session_revision';

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
    options.extra[_revisionKey] = _tokens.revision;
    try {
      if (!ApiEndpoints.withoutAccessToken.contains(options.path)) {
        final token = await _tokens.readAccessToken();
        if (!_sameSession(options)) {
          handler.reject(_cancelled(options));
          return;
        }
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
      handler.next(options);
    } on TokenStorageException catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      await _recover(err, handler);
    } on TokenStorageException catch (error) {
      handler.reject(
        DioException(requestOptions: err.requestOptions, error: error),
      );
    }
  }

  Future<void> _recover(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions request = err.requestOptions;
    final bool candidate =
        err.response?.statusCode == 401 &&
        !ApiEndpoints.withoutAccessToken.contains(request.path) &&
        request.extra[_retriedKey] != true;
    if (!candidate) {
      handler.next(err);
      return;
    }
    if (!_sameSession(request)) {
      handler.next(_cancelled(request));
      return;
    }

    final String? code = apiErrorCode(err.response?.data);
    if (code == ApiErrorCodes.accessTokenExpired) {
      final String? token;
      try {
        token = await _renewedAccessToken(request);
      } on DioException catch (error) {
        handler.next(error);
        return;
      }
      if (!_sameSession(request)) {
        handler.next(_cancelled(request));
        return;
      }
      if (token == null) {
        await _endSession(request);
        handler.next(err);
        return;
      }
      await _retry(request, token, handler);
      return;
    }

    if (_sessionEndingCodes.contains(code)) {
      await _endSession(request);
    }
    handler.next(err);
  }

  /// Returns a usable access token, or null when the session cannot be renewed.
  /// Throws a [DioException] when the renewal request itself fails to complete.
  Future<String?> _renewedAccessToken(RequestOptions failed) async {
    final String? current = await _tokens.readAccessToken();
    if (!_sameSession(failed)) throw _cancelled(failed);
    // An earlier request in the queue may already have renewed the token.
    if (current != null &&
        current.isNotEmpty &&
        failed.headers['Authorization'] != 'Bearer $current') {
      return current;
    }

    final String? refresh = await _tokens.readRefreshToken();
    if (!_sameSession(failed)) throw _cancelled(failed);
    if (refresh == null || refresh.isEmpty) return null;

    try {
      final Response<dynamic> response = await _plain.post<dynamic>(
        ApiEndpoints.refreshToken,
        data: <String, String>{'refresh_token': refresh},
      );
      final Object? body = response.data;
      final Object? token = body is Map ? body['access_token'] : null;
      if (token is! String || token.isEmpty) {
        throw DioException(
          requestOptions: failed,
          response: response,
          error: const FormatException('Missing refreshed access token.'),
        );
      }
      await _tokens.saveAccessToken(
        token,
        expectedRevision: failed.extra[_revisionKey] as int,
      );
      if (!_sameSession(failed)) throw _cancelled(failed);
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
    if (!_sameSession(request)) {
      handler.reject(_cancelled(request));
      return;
    }
    final RequestOptions retry = request.copyWith(
      headers: <String, dynamic>{
        ...request.headers,
        'Authorization': 'Bearer $token',
      },
      extra: <String, dynamic>{...request.extra, _retriedKey: true},
    );
    try {
      final response = await _plain.fetch<dynamic>(retry);
      if (!_sameSession(request)) {
        handler.reject(_cancelled(request));
        return;
      }
      handler.resolve(response);
    } on DioException catch (error) {
      if (!_sameSession(request)) {
        handler.reject(_cancelled(request));
        return;
      }
      if (error.response?.statusCode == 401 &&
          _sessionEndingCodes.contains(apiErrorCode(error.response?.data))) {
        await _endSession(request);
      }
      handler.reject(error);
    }
  }

  bool _sameSession(RequestOptions request) =>
      request.extra[_revisionKey] == _tokens.revision;

  DioException _cancelled(RequestOptions request) =>
      DioException(requestOptions: request, type: DioExceptionType.cancel);

  Future<void> _endSession(RequestOptions request) async {
    if (!_sameSession(request)) return;
    final revision = _tokens.revision;
    await _tokens.clear(expectedRevision: revision);
    if (_tokens.revision == revision + 1 && !_sessionEnded.isClosed) {
      _sessionEnded.add(null);
    }
  }
}
