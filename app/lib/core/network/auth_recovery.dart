import 'package:app/core/network/api_endpoints.dart';
import 'package:app/core/network/api_error_body.dart';
import 'package:app/core/network/auth_renewal.dart';
import 'package:app/core/network/auth_retry.dart';
import 'package:app/core/network/auth_session_scope.dart';
import 'package:dio/dio.dart';

/// Answers a 401: renews the token and retries, or ends the session.
mixin AuthRecovery on AuthSessionScope, AuthRenewal, AuthRetry {
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
