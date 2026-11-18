import 'package:app/core/network/api_error_body.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:dio/dio.dart';

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
