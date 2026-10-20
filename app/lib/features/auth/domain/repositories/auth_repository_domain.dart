import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:multiple_result/multiple_result.dart';

abstract class AuthRepositoryDomain {
  /// Sends the SMS code to [phone] (international form, +9665XXXXXXXX).
  Future<Result<bool, Failure>> requestCode(String phone);

  /// Checks the code. A wrong code gives an InvalidCodeFailure.
  Future<Result<SignInResult, Failure>> verifyCode(String phone, String code);

  /// Ends the session on the server and removes the tokens from this phone.
  /// Success means the server ended the session. A Failure means it could not
  /// be reached or refused, but the tokens are removed in both cases.
  Future<Result<bool, Failure>> signOut();
}
