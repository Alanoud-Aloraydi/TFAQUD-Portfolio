part of '../circles_remote_data_source.dart';

/// Creating a circle, asking a patient for one, and what waits for an
/// answer.
abstract interface class CircleRequestApi {
  /// POST /api/v1/circles/self.
  Future<CircleModel> createSelfCircle(NewSelfCircleModel body);

  /// POST /api/v1/circles/patient-without-account.
  Future<CircleModel> createPatientCircle(NewPatientCircleModel body);

  /// POST /api/v1/circle-requests.
  Future<SentCircleRequestModel> sendCircleRequest(NewCircleRequestModel body);

  /// GET /api/v1/circle-requests: the requests sent and the requests received.
  Future<CircleRequestsModel> getCircleRequests();

  /// GET /api/v1/invitations: invitations to manage a circle.
  Future<List<ReceivedInvitation>> getInvitations();

  /// GET /api/v1/notifications/previous: the invitations and requests
  /// answered in the last 30 days, newest first.
  Future<List<PreviousNotification>> getPreviousNotifications();
}
