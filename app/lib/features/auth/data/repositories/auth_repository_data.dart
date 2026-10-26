import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/network/api_error_body.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:app/features/auth/data/models/account_status_response.dart';
import 'package:app/features/auth/data/models/verify_code_response.dart';
import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:app/features/auth/domain/failures/invalid_code_failure.dart';
import 'package:app/features/auth/domain/failures/sign_in_failures.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@LazySingleton(as: AuthRepositoryDomain)
class AuthRepositoryData implements AuthRepositoryDomain {
  AuthRepositoryData(this._remote, this._tokens);

  final BaseAuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<Result<String, Failure>> requestCode(
    String phone, {
    String? verificationId,
  }) async {
    try {
      final String id = await _remote.requestCode(
        phone,
        verificationId: verificationId,
      );
      return Success(id);
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
  Future<Result<bool, Failure>> signOut() async {
    Result<bool, Failure> result = const Success(true);
    try {
      await _remote.signOut();
    } on Exception catch (error) {
      result = Error(FailureExceptions.getException(error));
    }
    try {
      await _tokens.clear();
    } on Exception {
      return const Error(StorageFailure('auth.sign_out_failed'));
    }
    return result;
  }

  @override
  Future<Result<SignInResult?, Failure>> restoreSession() async {
    try {
      final String? before = await _tokens.readAccessToken();
      if (before == null || before.isEmpty) return const Success(null);
      final AccountStatusResponse account = await _remote.checkSession();
      return Success(
        SignInResult(
          needsProfile: !account.profileComplete,
          appMode: account.appMode,
        ),
      );
    } on Exception catch (error) {
      try {
        final String? after = await _tokens.readAccessToken();
        if (after == null || after.isEmpty) return const Success(null);
      } on Exception {
        return const Error(StorageFailure());
      }
      return Error(FailureExceptions.getException(error));
    }
  }

  /// The API code decides the failure for the two code calls. Any other error
  /// (no connection, a timeout, a server error) goes to the shared mapping.
  Failure _signInFailure(Object error) {
    return switch (apiErrorCodeOf(error)) {
      ApiErrorCodes.invalidCode => const InvalidCodeFailure(),
      ApiErrorCodes.codeExpired => const CodeExpiredFailure(),
      ApiErrorCodes.tooManyAttempts => const TooManyAttemptsFailure(),
      ApiErrorCodes.tooManyCodes => const TooManyCodesFailure(),
      ApiErrorCodes.verificationNotFound ||
      ApiErrorCodes.codeAlreadyUsed => const StartAgainFailure(),
      ApiErrorCodes.smsUnavailable => const SmsUnavailableFailure(),
      _ => FailureExceptions.getException(error),
    };
  }
}
