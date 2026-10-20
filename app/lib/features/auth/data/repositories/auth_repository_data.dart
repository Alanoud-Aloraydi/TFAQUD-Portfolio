import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/services/token_storage.dart';
import 'package:app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:app/features/auth/domain/repositories/auth_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@LazySingleton(as: AuthRepositoryDomain)
class AuthRepositoryData implements AuthRepositoryDomain {
  AuthRepositoryData(this._remote, this._tokens);

  final BaseAuthRemoteDataSource _remote;
  final TokenStorage _tokens;

  @override
  Future<Result<bool, Failure>> signOut() async {
    try {
      await _remote.signOut();
      return Success(true);
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    } finally {
      // The user asked to leave this phone, so the tokens are removed even if
      // the call to the server failed.
      await _tokens.clear();
    }
  }
}
