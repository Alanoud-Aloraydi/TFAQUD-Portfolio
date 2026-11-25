import 'package:app/core/network/api_error_body.dart';
import 'package:app/core/network/auth_renewal.dart';
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

/// Sends a failed request again with a renewed token.
mixin AuthRetry on AuthSessionScope {
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
}
