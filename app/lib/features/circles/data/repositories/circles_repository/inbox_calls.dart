part of 'package:app/features/circles/data/repositories/circles_repository_impl.dart';

/// The requests and invitations waiting for an answer, and the answered ones.
mixin _InboxCalls implements CirclesRepository {
  BaseCirclesRemoteDataSource get _remote;

  /// What was answered lately. It is only history: when it cannot be read
  /// (a server from before it, a dropped connection), what waits for an
  /// answer still shows, with nothing under «السابقة».
  Future<List<PreviousNotification>> _previousNotifications() async {
    try {
      return await _remote.getPreviousNotifications();
    } catch (_) {
      return const <PreviousNotification>[];
    }
  }

  @override
  Future<Result<CircleInbox, Failure>> getInbox() async {
    try {
      // The lists are independent, so they are read at the same time.
      final List<Object> answers = await Future.wait<Object>(<Future<Object>>[
        _remote.getCircleRequests(),
        _remote.getInvitations(),
        _previousNotifications(),
      ]);
      final CircleRequestsModel requests = answers[0] as CircleRequestsModel;
      return Success(
        CircleInbox(
          sent: requests.sent,
          received: requests.received,
          invitations: answers[1] as List<ReceivedInvitation>,
          previous: answers[2] as List<PreviousNotification>,
        ),
      );
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }
}
