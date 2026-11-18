/// The requests to a patient and the invitations to manage a circle, and
/// the bell's answered ones (backend/app/circles/routes.py).
abstract final class CircleRequestEndpoints {
  static const String circleRequests = '/circle-requests';
  static const String invitations = '/invitations';

  /// The invitations and requests answered in the last 30 days, for the
  /// bell's «السابقة».
  static const String previousNotifications = '/notifications/previous';

  /// One request: `/circle-requests/{id}`. A request is read from the list; the
  /// patient answers it with [respondCircleRequest] and completes it with
  /// [completeCircleRequest]; either side cancels it with DELETE on this path.
  static String circleRequest(String id) => '$circleRequests/$id';
  static String respondCircleRequest(String id) =>
      '${circleRequest(id)}/respond';
  static String completeCircleRequest(String id) =>
      '${circleRequest(id)}/complete';

  /// The answer to an invitation to manage a circle.
  static String respondInvitation(String id) => '$invitations/$id/respond';
}
