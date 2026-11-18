part of '../circles_remote_data_source.dart';

/// The calls that answer, complete or cancel a request or an invitation.
mixin _ReplyRequests implements CircleReplyApi {
  DioClient get _client;

  @override
  Future<SentCircleRequestModel> respondToRequest(
    String id, {
    required bool accept,
  }) async {
    final response = await _client.post(
      CircleRequestEndpoints.respondCircleRequest(id),
      data: <String, dynamic>{'accept': accept},
    );
    return SentCircleRequestModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  @override
  Future<String?> respondToInvitation(String id, {required bool accept}) async {
    final response = await _client.post(
      CircleRequestEndpoints.respondInvitation(id),
      data: <String, dynamic>{'accept': accept},
    );
    final Map<String, dynamic> body = response.data as Map<String, dynamic>;
    final Map<String, dynamic> invitation =
        body['invitation'] as Map<String, dynamic>;
    return invitation['care_circle_id'] as String?;
  }

  @override
  Future<CircleModel> completeRequest(
    String id,
    CompleteCircleRequestModel body,
  ) async {
    final response = await _client.post(
      CircleRequestEndpoints.completeCircleRequest(id),
      data: body.toJson(),
    );
    return CircleModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> cancelRequest(String id) async {
    await _client.delete(CircleRequestEndpoints.circleRequest(id));
  }
}
