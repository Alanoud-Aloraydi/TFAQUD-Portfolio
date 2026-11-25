import 'dart:async';

import 'package:app/core/network/api_error_body.dart';
import 'package:app/core/network/auth_interceptor.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Ends the sign-in an earlier install of the app left in the Keychain.
///
/// [end] takes the tokens out at once, so the app opens signed out, and
/// signs that session out on the server without making the start wait. If
/// the phone is offline the server ends it later by itself: OneSignal tells
/// it the deleted app's subscription is no longer active.
class LeftoverSignIn {
  /// [api] is a client without the sign-in interceptor: these tokens are not
  /// the app's any more, so nothing may renew or keep them.
  LeftoverSignIn(this._tokens, this._api);

  final TokenStorage _tokens;
  final Dio _api;
  Future<void> _server = Future<void>.value();

  /// The server's sign-out that [end] started; tests wait for it.
  @visibleForTesting
  Future<void> get serverSignOut => _server;

  /// Takes out the tokens found and starts their sign-out on the server.
  Future<void> end() async {
    final String? access;
    final String? refresh;
    try {
      access = await _tokens.readAccessToken();
      refresh = await _tokens.readRefreshToken();
      if (refresh == null || refresh.isEmpty) return;
      await _tokens.clear();
    } on TokenStorageException {
      return;
    }
    _server = _signOut(access, refresh);
    unawaited(_server);
  }

  /// Signs the session out with its access token; with a new one from the
  /// refresh token when that has expired. Never throws.
  Future<void> _signOut(String? access, String refresh) async {
    try {
      if (access != null && access.isNotEmpty) {
        try {
          await _post(access);
          return;
        } on DioException catch (error) {
          // Only an expired access token is worth a second try.
          final String? code = apiErrorCode(error.response?.data);
          if (code != ApiErrorCodes.accessTokenExpired) return;
        }
      }
      final Response<dynamic> renewed = await _api.post<dynamic>(
        AuthEndpoints.refreshToken,
        data: <String, String>{'refresh_token': refresh},
      );
      final Object? body = renewed.data;
      final Object? token = body is Map ? body['access_token'] : null;
      if (token is String && token.isNotEmpty) await _post(token);
    } on Exception {
      // Offline, or already signed out: the server ends it by itself.
    }
  }

  Future<void> _post(String access) => _api.post<void>(
    AuthEndpoints.signOut,
    options: Options(
      headers: <String, String>{'Authorization': 'Bearer $access'},
    ),
  );
}
