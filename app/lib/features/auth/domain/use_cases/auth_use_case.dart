import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@lazySingleton
class AuthUseCase {
  AuthUseCase(this._repository);

  final AuthRepositoryDomain _repository;

  Future<Result<bool, Failure>> signOut() => _repository.signOut();
}
