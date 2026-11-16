part of '../circles_repository_data.dart';

/// Creating a circle, and asking a patient for one.
mixin _CircleCreationCalls implements CirclesRepositoryDomain {
  BaseCirclesRemoteDataSource get _remote;
  Future<String> _newPatientZone(String city);

  @override
  Future<Result<CareCircleSummary, Failure>> createSelfCircle(
    NewSelfCircle circle,
  ) async {
    try {
      final created = await _remote.createSelfCircle(
        NewSelfCircleModel(circle, await _newPatientZone(circle.city)),
      );
      return Success(created.toEntity());
    } catch (error) {
      return Error(_circleFailure(error));
    }
  }

  @override
  Future<Result<CareCircleSummary, Failure>> createPatientCircle(
    NewPatientCircle circle,
  ) async {
    try {
      final created = await _remote.createPatientCircle(
        NewPatientCircleModel(circle, await _newPatientZone(circle.city)),
      );
      return Success(created.toEntity());
    } catch (error) {
      return Error(_circleFailure(error));
    }
  }

  @override
  Future<Result<SentCircleRequest, Failure>> sendCircleRequest(
    NewCircleRequest request,
  ) async {
    try {
      final sent = await _remote.sendCircleRequest(
        NewCircleRequestModel(request),
      );
      return Success(sent.toEntity());
    } catch (error) {
      return Error(_requestFailure(error));
    }
  }
}
