import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/network/api_error_body.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:app/features/auth/data/datasources/auth_session_calls.dart';
import 'package:app/features/auth/data/models/verify_code_response.dart';
import 'package:app/features/auth/domain/entities/code_request.dart';
import 'package:app/features/auth/domain/entities/invalid_code_failure.dart';
import 'package:app/features/auth/domain/entities/sign_in_failures.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:multiple_result/multiple_result.dart';

/// Signs in through the API, turning a refusal into a [Failure].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokens);

  final BaseAuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<Result<CodeRequest, Failure>> requestCode(
    String phone, {
    String? verificationId,
  }) async {
    try {
      final CodeRequest sent = await _remote.requestCode(
        phone,
        verificationId: verificationId,
      );
      return Success(sent);
    } catch (error) {
      return Error(_signInFailure(error));
    }
  }

  @override
  Future<Result<SignInResult, Failure>> verifyCode({
    required String verificationId,
    required String code,
  }) async {
    try {
      final VerifyCodeResponse response = await _remote.verifyCode(
        verificationId: verificationId,
        code: code,
      );
      await _tokens.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      return Success(
        SignInResult(
          needsProfile: !response.profileComplete,
          appMode: response.appMode,
        ),
      );
    } catch (error) {
      return Error(_signInFailure(error));
    }
  }

  @override
  Future<Result<bool, Failure>> signOut() => signOutSession(_remote, _tokens);

  @override
  Future<Result<SignInResult?, Failure>> restoreSession() =>
      restoreStoredSession(_remote, _tokens);

  /// The API code decides the failure for the two code calls. Any other error
  /// (no connection, a timeout, a server error) goes to the shared mapping.
  Failure _signInFailure(Object error) {
    return switch (apiErrorCodeOf(error)) {
      ApiErrorCodes.invalidCode => const InvalidCodeFailure(),
      ApiErrorCodes.codeExpired => const CodeExpiredFailure(),
      ApiErrorCodes.tooManyAttempts => const TooManyAttemptsFailure(),
      ApiErrorCodes.tooManyCodes => const TooManyCodesFailure(),
      ApiErrorCodes.resendWait => ResendWaitFailure(
        apiRetryAfterOf(error) ?? SignInFailureDefaults.resendWaitSeconds,
      ),
      ApiErrorCodes.verificationNotFound ||
      ApiErrorCodes.codeAlreadyUsed => const StartAgainFailure(),
      ApiErrorCodes.smsUnavailable => const SmsUnavailableFailure(),
      _ => FailureExceptions.getException(error),
    };
  }
}
