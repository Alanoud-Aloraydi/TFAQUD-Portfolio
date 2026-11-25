import 'dart:async';

import 'package:app/core/network/api_error_body.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Attaches the access token and renews it when the API reports it expired.
///
/// Queued renewal shares credentials only within the originating session.
class AuthInterceptor extends QueuedInterceptor with AuthSessionScope {
  AuthInterceptor(this._tokens);

  final TokenStorage _tokens;
  final StreamController<void> _sessionEnded =
      StreamController<void>.broadcast();
  Dio? _plainDio;

  /// Emits when the tokens were cleared because the session can no longer be
  /// renewed. The user has to sign in again.
  Stream<void> get sessionEnded => _sessionEnded.stream;

  @override
  TokenStorage get tokens => _tokens;

  @override
  Dio get plain => _plainDio ??= Dio(buildApiOptions());

  @override
  void notifySessionEnded() {
    if (!_sessionEnded.isClosed) _sessionEnded.add(null);
  }

  @visibleForTesting
  set plainDio(Dio dio) => _plainDio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.extra[authRevisionKey] = _tokens.revision;
    try {
      if (!ApiEndpoints.withoutAccessToken.contains(options.path)) {
        final token = await _tokens.readAccessToken();
        if (!sameSession(options)) {
          handler.reject(cancelled(options));
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
      await recover(err, handler);
    } on TokenStorageException catch (error) {
      handler.reject(
        DioException(requestOptions: err.requestOptions, error: error),
      );
    }
  }

  /// Returns a usable access token, or null when the session cannot be renewed.
  /// Throws a [DioException] when the renewal request itself fails to complete.
  Future<String?> renewedAccessToken(RequestOptions failed) async {
    final String? current = await tokens.readAccessToken();
    if (!sameSession(failed)) throw cancelled(failed);
    // An earlier request in the queue may already have renewed the token.
    if (current != null &&
        current.isNotEmpty &&
        failed.headers['Authorization'] != 'Bearer $current') {
      return current;
    }

    final String? refresh = await tokens.readRefreshToken();
    if (!sameSession(failed)) throw cancelled(failed);
    if (refresh == null || refresh.isEmpty) return null;

    try {
      final Response<dynamic> response = await plain.post<dynamic>(
        AuthEndpoints.refreshToken,
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
      await tokens.saveAccessToken(
        token,
        expectedRevision: failed.extra[authRevisionKey] as int,
      );
      if (!sameSession(failed)) throw cancelled(failed);
      return token;
    } on DioException catch (error) {
      // The API rejected the refresh token: the session is over.
      if (error.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<void> retry(
    RequestOptions request,
    String token,
    ErrorInterceptorHandler handler,
  ) async {
    if (!sameSession(request)) {
      handler.reject(cancelled(request));
      return;
    }
    final RequestOptions retry = request.copyWith(
      headers: <String, dynamic>{
        ...request.headers,
        'Authorization': 'Bearer $token',
      },
      extra: <String, dynamic>{...request.extra, authRetriedKey: true},
    );
    try {
      final response = await plain.fetch<dynamic>(retry);
      if (!sameSession(request)) {
        handler.reject(cancelled(request));
        return;
      }
      handler.resolve(response);
    } on DioException catch (error) {
      if (!sameSession(request)) {
        handler.reject(cancelled(request));
        return;
      }
      if (error.response?.statusCode == 401 &&
          authSessionEndingCodes.contains(apiErrorCode(error.response?.data))) {
        await endSession(request);
      }
      handler.reject(error);
    }
  }

  /// Decides whether a failed request is renewed, retried or ends the session.
  Future<void> recover(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final RequestOptions request = err.requestOptions;
    final bool candidate =
        err.response?.statusCode == 401 &&
        !ApiEndpoints.withoutAccessToken.contains(request.path) &&
        request.extra[authRetriedKey] != true;
    if (!candidate) {
      handler.next(err);
      return;
    }
    if (!sameSession(request)) {
      handler.next(cancelled(request));
      return;
    }

    final String? code = apiErrorCode(err.response?.data);
    if (code == ApiErrorCodes.accessTokenExpired) {
      final String? token;
      try {
        token = await renewedAccessToken(request);
      } on DioException catch (error) {
        handler.next(error);
        return;
      }
      if (!sameSession(request)) {
        handler.next(cancelled(request));
        return;
      }
      if (token == null) {
        await endSession(request);
        handler.next(err);
        return;
      }
      await retry(request, token, handler);
      return;
    }

    if (authSessionEndingCodes.contains(code)) {
      await endSession(request);
    }
    handler.next(err);
  }
}

/// The sign-in routes of the API (backend/app/auth/routes.py): the code by
/// SMS, the session and its renewal.
abstract final class AuthEndpoints {
  static const String refreshToken = '/auth/refresh';
  static const String signOut = '/auth/sign-out';
  static const String session = '/auth/session';
  static const String requestCode = '/auth/request-code';
  static const String verifyCode = '/auth/verify-code';
}

const String authRetriedKey = 'auth_retried';
const String authRevisionKey = 'auth_session_revision';

/// 401 codes after which the stored tokens can no longer be used.
const Set<String> authSessionEndingCodes = <String>{
  ApiErrorCodes.missingToken,
  ApiErrorCodes.invalidToken,
  ApiErrorCodes.sessionRevoked,
  ApiErrorCodes.invalidRefreshToken,
};

/// What the auth interceptor parts share: the tokens, the plain client and
/// the session checks.
mixin AuthSessionScope {
  TokenStorage get tokens;

  /// Client without the interceptor, for the renewal and the retry.
  Dio get plain;

  /// Emits when the tokens were cleared and the user has to sign in again.
  void notifySessionEnded();

  bool sameSession(RequestOptions request) =>
      request.extra[authRevisionKey] == tokens.revision;

  DioException cancelled(RequestOptions request) =>
      DioException(requestOptions: request, type: DioExceptionType.cancel);

  Future<void> endSession(RequestOptions request) async {
    if (!sameSession(request)) return;
    final revision = tokens.revision;
    await tokens.clear(expectedRevision: revision);
    if (tokens.revision == revision + 1) notifySessionEnded();
  }
}
