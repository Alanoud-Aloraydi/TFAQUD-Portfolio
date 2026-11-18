import 'package:app/core/network/auth_session_scope.dart';
import 'package:dio/dio.dart';
import 'package:app/core/network/auth_endpoints.dart';

/// Renews the access token with the refresh token.
mixin AuthRenewal on AuthSessionScope {
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
}
