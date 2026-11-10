import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/entities/code_request.dart';
import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@lazySingleton
/// Exposes auth domain operations.
class AuthUseCase {
  AuthUseCase(this._repository);

  final AuthRepositoryDomain _repository;

  /// Sends a sign-in code. See [AuthRepositoryDomain.requestCode].
  Future<Result<CodeRequest, Failure>> requestCode(
    String phone, {
    String? verificationId,
  }) => _repository.requestCode(phone, verificationId: verificationId);

  /// Checks a code and signs in. See [AuthRepositoryDomain.verifyCode].
  Future<Result<SignInResult, Failure>> verifyCode({
    required String verificationId,
    required String code,
  }) => _repository.verifyCode(verificationId: verificationId, code: code);

  /// Ends the session. See [AuthRepositoryDomain.signOut].
  Future<Result<bool, Failure>> signOut() => _repository.signOut();

  /// Restores the session. See [AuthRepositoryDomain.restoreSession].
  Future<Result<SignInResult?, Failure>> restoreSession() =>
      _repository.restoreSession();
}
