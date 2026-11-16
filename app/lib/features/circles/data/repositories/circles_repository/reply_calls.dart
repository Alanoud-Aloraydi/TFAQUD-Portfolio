part of '../circles_repository_data.dart';

/// Answering a request or an invitation, completing a request, canceling one.
mixin _ReplyCalls implements CirclesRepositoryDomain {
  BaseCirclesRemoteDataSource get _remote;
  Future<String> _newPatientZone(String city);

  @override
  Future<Result<CircleRequestStatus, Failure>> respondToRequest(
    String id, {
    required bool accept,
  }) async {
    try {
      final answer = await _remote.respondToRequest(id, accept: accept);
      return Success(answer.toEntity().status);
    } catch (error) {
      return Error(_replyFailure(error));
    }
  }

  @override
  Future<Result<String?, Failure>> respondToInvitation(
    String id, {
    required bool accept,
  }) async {
    try {
      return Success<String?, Failure>(
        await _remote.respondToInvitation(id, accept: accept),
      );
    } catch (error) {
      return Error(_replyFailure(error));
    }
  }

  @override
  Future<Result<(CareCircleSummary, CircleAppMode), Failure>> completeRequest(
    String id,
    CompleteCircleRequest request,
  ) async {
    try {
      final created = await _remote.completeRequest(
        id,
        CompleteCircleRequestModel(
          request,
          await _newPatientZone(request.city),
        ),
      );
      return Success((created.toEntity(), created.accountAppMode));
    } catch (error) {
      return Error(_replyFailure(error));
    }
  }

  @override
  Future<Result<void, Failure>> cancelRequest(String id) async {
    try {
      await _remote.cancelRequest(id);
      return const Success(null);
    } catch (error) {
      return Error(_replyFailure(error));
    }
  }
}
