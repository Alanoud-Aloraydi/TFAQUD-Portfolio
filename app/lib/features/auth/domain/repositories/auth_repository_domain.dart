import 'package:app/core/errors/failure.dart';
import 'package:app/features/auth/domain/entities/sign_in_result.dart';
import 'package:multiple_result/multiple_result.dart';

abstract class AuthRepositoryDomain {
  /// Sends the SMS code to [phone] (international form, +9665XXXXXXXX) and
  /// returns the verification id of the request.
  ///
  /// Pass the id of an earlier call as [verificationId] to send another SMS for
  /// the same request (a resend): the wrong tries already used stay used.
  /// Without it a new request starts, with its own tries.
  Future<Result<String, Failure>> requestCode(
    String phone, {
    String? verificationId,
  });

  /// Checks the code of the request. On success the tokens are saved on this
  /// phone. A wrong code gives an InvalidCodeFailure.
  Future<Result<SignInResult, Failure>> verifyCode({
    required String verificationId,
    required String code,
  });

  /// Ends the session on the server and removes the tokens from this phone.
  /// Success means the server ended the session. A Failure means it could not
  /// be reached or refused, but the tokens are removed in both cases.
  Future<Result<bool, Failure>> signOut();

  /// Restores verified account state, or null when no session remains.
  /// Connection failures preserve the tokens and return a retryable failure.
  Future<Result<SignInResult?, Failure>> restoreSession();
}
