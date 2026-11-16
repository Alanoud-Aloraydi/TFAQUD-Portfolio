part of '../circles_repository_data.dart';

/// What a member may edit, who leads the circle, and leaving it.
mixin _MemberCalls implements CirclesRepositoryDomain {
  BaseCirclesRemoteDataSource get _remote;

  @override
  Future<Result<void, Failure>> setMemberEditAccess(
    String circleId,
    String accountId, {
    required String area,
    required bool allowed,
  }) async {
    try {
      await _remote.setMemberEditAccess(
        circleId,
        accountId,
        area: area,
        allowed: allowed,
      );
      return const Success(null);
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  Future<Result<void, Failure>> handOverLeadership(
    String circleId,
    String accountId,
  ) async {
    try {
      await _remote.handOverLeadership(circleId, accountId);
      return const Success(null);
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  Future<Result<void, Failure>> removeMember(
    String circleId,
    String accountId,
  ) async {
    try {
      await _remote.removeMember(circleId, accountId);
      return const Success(null);
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  Future<Result<void, Failure>> leaveCircle(
    String circleId, {
    required bool confirmDelete,
  }) async {
    try {
      await _remote.leaveCircle(circleId, confirmDelete: confirmDelete);
      return const Success(null);
    } catch (error) {
      return Error(switch (apiErrorCodeOf(error)) {
        ApiErrorCodes.confirmationRequired => const LeaveDeletesCircleFailure(),
        _ => FailureExceptions.getException(error),
      });
    }
  }
}
