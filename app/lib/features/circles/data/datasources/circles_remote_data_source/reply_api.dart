part of '../circles_remote_data_source.dart';

/// Answering a request or an invitation, and completing or canceling a
/// request.
abstract interface class CircleReplyApi {
  /// POST /api/v1/circle-requests/{id}/respond.
  Future<SentCircleRequestModel> respondToRequest(
    String id, {
    required bool accept,
  });

  /// POST /api/v1/invitations/{id}/respond. Returns the id of the circle when
  /// the invitation was accepted, and null when it was declined.
  Future<String?> respondToInvitation(String id, {required bool accept});

  /// POST /api/v1/circle-requests/{id}/complete.
  Future<CircleModel> completeRequest(
    String id,
    CompleteCircleRequestModel body,
  );

  /// DELETE /api/v1/circle-requests/{id}.
  Future<void> cancelRequest(String id);
}
