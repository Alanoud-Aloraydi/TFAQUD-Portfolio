part of '../circles_repository_data.dart';

/// Reading the signed-in account and a circle's overview, and deleting the
/// account.
mixin _AccountCalls implements CirclesRepositoryDomain {
  BaseCirclesRemoteDataSource get _remote;

  @override
  Future<Result<AccountSummary, Failure>> getAccount() async {
    try {
      return Success((await _remote.getAccount()).toEntity());
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  Future<Result<CircleOverview, Failure>> getCircleOverview(
    String circleId,
  ) async {
    try {
      return Success((await _remote.getCircleOverview(circleId)).overview);
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  Future<Result<void, Failure>> deleteAccount(AccountDeletion deletion) async {
    try {
      await _remote.deleteAccount(deletion);
      return const Success(null);
    } catch (error) {
      return Error(switch (apiErrorCodeOf(error)) {
        ApiErrorCodes.patientChoiceRequired =>
          const PatientChoiceRequiredFailure(),
        ApiErrorCodes.lastManager => const LastManagerFailure(),
        _ => FailureExceptions.getException(error),
      });
    }
  }
}
