part of '../circles_remote_data_source.dart';

/// The calls that create a circle and read what waits for an answer.
mixin _CircleRequestRequests implements CircleRequestApi {
  DioClient get _client;

  @override
  Future<CircleModel> createSelfCircle(NewSelfCircleModel body) async {
    final response = await _client.post(
      CircleEndpoints.selfCircle,
      data: body.toJson(),
    );
    return CircleModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<CircleModel> createPatientCircle(NewPatientCircleModel body) async {
    final response = await _client.post(
      CircleEndpoints.patientCircle,
      data: body.toJson(),
    );
    return CircleModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SentCircleRequestModel> sendCircleRequest(
    NewCircleRequestModel body,
  ) async {
    final response = await _client.post(
      CircleRequestEndpoints.circleRequests,
      data: body.toJson(),
    );
    return SentCircleRequestModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<CircleRequestsModel> getCircleRequests() async {
    final response = await _client.get(CircleRequestEndpoints.circleRequests);
    return CircleRequestsModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<ReceivedInvitation>> getInvitations() async {
    final response = await _client.get(CircleRequestEndpoints.invitations);
    return ReceivedInvitationsModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<List<PreviousNotification>> getPreviousNotifications() async {
    final response = await _client.get(
      CircleRequestEndpoints.previousNotifications,
    );
    return PreviousNotificationsModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
