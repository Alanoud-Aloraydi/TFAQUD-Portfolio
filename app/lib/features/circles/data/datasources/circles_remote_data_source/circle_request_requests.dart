part of '../circles_remote_data_source.dart';

/// The calls that create a circle and read what waits for an answer.
mixin _CircleRequestRequests implements CircleRequestApi {
  DioClient get _client;

  @override
  Future<CircleModel> createSelfCircle(NewSelfCircleModel body) async {
    final response = await _client.post(
      ApiEndpoints.selfCircle,
      data: body.toJson(),
    );
    return CircleModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CircleModel> createPatientCircle(NewPatientCircleModel body) async {
    final response = await _client.post(
      ApiEndpoints.patientCircle,
      data: body.toJson(),
    );
    return CircleModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SentCircleRequestModel> sendCircleRequest(
    NewCircleRequestModel body,
  ) async {
    final response = await _client.post(
      ApiEndpoints.circleRequests,
      data: body.toJson(),
    );
    return SentCircleRequestModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<CircleRequestsModel> getCircleRequests() async {
    final response = await _client.get(ApiEndpoints.circleRequests);
    return CircleRequestsModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<ReceivedInvitation>> getInvitations() async {
    final response = await _client.get(ApiEndpoints.invitations);
    return ReceivedInvitationsModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<PreviousNotification>> getPreviousNotifications() async {
    final response = await _client.get(ApiEndpoints.previousNotifications);
    return PreviousNotificationsModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
