part of 'package:app/features/circles/data/repositories/circles_repository_impl.dart';

/// Inviting a manager to a circle, and sending or canceling that invitation.
mixin _ManagerInvitationCalls implements CirclesRepository {
  BaseCirclesRemoteDataSource get _remote;

  @override
  Future<Result<void, Failure>> inviteManager(
    String circleId,
    String phoneNumber,
  ) async {
    try {
      await _remote.inviteManager(circleId, phoneNumber);
      return const Success(null);
    } catch (error) {
      return Error(switch (apiErrorCodeOf(error)) {
        ApiErrorCodes.selfInvitation => const SelfInvitationFailure(),
        ApiErrorCodes.alreadyManager => const AlreadyManagerFailure(),
        _ => FailureExceptions.getException(error),
      });
    }
  }

  @override
  Future<Result<void, Failure>> resendManagerInvitation(
    String circleId,
    String invitationId,
  ) async {
    try {
      await _remote.resendManagerInvitation(circleId, invitationId);
      return const Success(null);
    } catch (error) {
      return Error(_invitationFailure(error));
    }
  }

  @override
  Future<Result<void, Failure>> cancelManagerInvitation(
    String circleId,
    String invitationId,
  ) async {
    try {
      await _remote.cancelManagerInvitation(circleId, invitationId);
      return const Success(null);
    } catch (error) {
      return Error(_invitationFailure(error));
    }
  }
}
