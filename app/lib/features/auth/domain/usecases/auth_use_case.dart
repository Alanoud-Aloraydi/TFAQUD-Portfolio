import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/entities/code_request.dart';
import 'package:app/features/auth/domain/entities/sign_in_failures.dart';
import 'package:app/features/auth/domain/repositories/auth_repository.dart';
import 'package:multiple_result/multiple_result.dart';

/// The sign-in steps the application is allowed to take.
class AuthUseCase {
  AuthUseCase(this._repository);

  final AuthRepository _repository;

  /// Sends a sign-in code. See [AuthRepository.requestCode].
  Future<Result<CodeRequest, Failure>> requestCode(
    String phone, {
    String? verificationId,
  }) => _repository.requestCode(phone, verificationId: verificationId);

  /// Checks a code and signs in. See [AuthRepository.verifyCode].
  Future<Result<SignInResult, Failure>> verifyCode({
    required String verificationId,
    required String code,
  }) => _repository.verifyCode(verificationId: verificationId, code: code);

  /// Ends the session. See [AuthRepository.signOut].
  Future<Result<bool, Failure>> signOut() => _repository.signOut();

  /// Restores the session. See [AuthRepository.restoreSession].
  Future<Result<SignInResult?, Failure>> restoreSession() =>
      _repository.restoreSession();
}
