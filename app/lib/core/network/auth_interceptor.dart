import 'dart:async';

import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/api_options.dart';
import 'package:app/core/network/auth_recovery.dart';
import 'package:app/core/network/auth_renewal.dart';
import 'package:app/core/network/auth_retry.dart';
import 'package:app/core/network/auth_session_scope.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:injectable/injectable.dart';

/// Attaches the access token and renews it when the API reports it expired.
///
/// Queued renewal shares credentials only within the originating session.
@lazySingleton
class AuthInterceptor extends QueuedInterceptor
    with AuthSessionScope, AuthRenewal, AuthRetry, AuthRecovery {
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
}
