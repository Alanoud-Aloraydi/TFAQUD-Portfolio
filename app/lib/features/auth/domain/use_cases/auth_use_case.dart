import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@lazySingleton
class AuthUseCase {
  AuthUseCase(this._repository);

  final AuthRepositoryDomain _repository;

  Future<Result<String, Failure>> requestCode(
    String phone, {
    String? verificationId,
  }) => _repository.requestCode(phone, verificationId: verificationId);

  Future<Result<SignInResult, Failure>> verifyCode({
    required String verificationId,
    required String code,
  }) => _repository.verifyCode(verificationId: verificationId, code: code);

  Future<Result<bool, Failure>> signOut() => _repository.signOut();

  Future<bool> hasSession() => _repository.hasSession();
}
