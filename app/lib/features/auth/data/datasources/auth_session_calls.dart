import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/errors/storage_failures.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:app/features/auth/data/models/account_status_response.dart';
import 'package:app/features/auth/domain/entities/sign_in_failures.dart';
import 'package:multiple_result/multiple_result.dart';

/// Revokes the session on the server, then clears the tokens either way.
Future<Result<bool, Failure>> signOutSession(
  BaseAuthRemoteDataSource remote,
  TokenStorage tokens,
) async {
  final revision = tokens.revision;
  Result<bool, Failure> result = const Success(true);
  try {
    await remote.signOut();
  } on Exception catch (error) {
    result = Error(FailureExceptions.getException(error));
  }
  try {
    await tokens.clear(expectedRevision: revision);
  } on Exception {
    return const Error(StorageFailure('auth.sign_out_failed'));
  }
  return result;
}

/// Asks the server about the stored session, if there is one.
Future<Result<SignInResult?, Failure>> restoreStoredSession(
  BaseAuthRemoteDataSource remote,
  TokenStorage tokens,
) async {
  try {
    final String? before = await tokens.readAccessToken();
    if (before == null || before.isEmpty) return const Success(null);
    final AccountStatusResponse account = await remote.checkSession();
    return Success(
      SignInResult(
        needsProfile: !account.profileComplete,
        appMode: account.appMode,
      ),
    );
  } on Exception catch (error) {
    try {
      final String? after = await tokens.readAccessToken();
      if (after == null || after.isEmpty) return const Success(null);
    } on Exception {
      return const Error(StorageFailure());
    }
    return Error(FailureExceptions.getException(error));
  }
}
