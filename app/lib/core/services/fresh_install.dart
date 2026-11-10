import 'dart:async';
import 'dart:io';

import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/api_error_body.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether this start is the first one of a new install of the app.
///
/// iOS gives an app no word when it is deleted. It deletes the app's own
/// files and preferences with it, but keeps what the app put in the
/// Keychain: the session tokens. So deleting the app and installing it again
/// would open signed in as before. The first start of an install finds that
/// out here, and [LeftoverSignIn] signs that sign-in out.
abstract final class FreshInstall {
  /// Written at the first start; it goes when the app is deleted.
  static const String _markKey = 'install_started';

  /// The file GetStorage makes at every start, since the app's first build
  /// (core/setup.dart). An update from a build older than [_markKey] has it;
  /// a new install does not, yet.
  static const String _olderBuildsFile = 'GetStorage.gs';

  static bool _firstStart = false;

  /// Whether [check] found this start to be the first of a new install.
  static bool get firstStart => _firstStart;

  /// Finds out once, at the start, before `GetStorage.init` (which makes
  /// [_olderBuildsFile]). When it cannot tell, the start is not counted as
  /// a first one: no one is signed out by mistake.
  static Future<void> check({
    Future<bool> Function()? olderBuildStarted,
  }) async {
    _firstStart = false;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_markKey) ?? false) return;
      final bool updated = await (olderBuildStarted ?? _olderBuildStarted)();
      await prefs.setBool(_markKey, true);
      _firstStart = !updated;
    } catch (_) {
      // Unknown: as a start like any other.
    }
  }

  static Future<bool> _olderBuildStarted() async {
    final Directory documents = await getApplicationDocumentsDirectory();
    return File('${documents.path}/$_olderBuildsFile').exists();
  }
}

/// Ends the sign-in an earlier install of the app left in the Keychain.
///
/// [end] takes the tokens out at once, so the app opens signed out, and
/// signs that session out on the server without making the start wait. If
/// the phone is offline the server ends it later by itself: Apple tells it
/// the deleted app's push token is no longer active.
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
        ApiEndpoints.refreshToken,
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
    ApiEndpoints.signOut,
    options: Options(
      headers: <String, String>{'Authorization': 'Bearer $access'},
    ),
  );
}
