import 'package:app/core/errors/failure.dart';
import 'package:multiple_result/multiple_result.dart';

abstract class AuthRepositoryDomain {
  /// Ends the session on the server and removes the tokens from this phone.
  /// Success means the server ended the session. A Failure means it could not
  /// be reached or refused, but the tokens are removed in both cases.
  Future<Result<bool, Failure>> signOut();
}
