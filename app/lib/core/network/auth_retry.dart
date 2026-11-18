import 'package:app/core/network/api_error_body.dart';
import 'package:app/core/network/auth_session_scope.dart';
import 'package:dio/dio.dart';

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
