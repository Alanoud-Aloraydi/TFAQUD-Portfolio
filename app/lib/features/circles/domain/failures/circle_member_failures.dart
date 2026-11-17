import 'package:app/core/errors/failure.dart';

/// The invited number is the inviter's own.
class SelfInvitationFailure extends Failure {
  const SelfInvitationFailure() : super('circle_overview.self_invitation');
}

/// The invited number already manages this circle.
class AlreadyManagerFailure extends Failure {
  const AlreadyManagerFailure() : super('circle_overview.already_manager');
}

/// The invitation is no longer pending, or no longer exists: someone
/// answered or canceled it meanwhile. The list is read again.
class InvitationUnavailableFailure extends Failure {
  const InvitationUnavailableFailure()
    : super('circle_overview.invitation_unavailable');
}

/// Leaving now deletes the circle (the other managers left meanwhile), and
/// the person agreed only to leave. The tab reads the circle again, so the
/// next tap asks to delete it.
class LeaveDeletesCircleFailure extends Failure {
  const LeaveDeletesCircleFailure()
    : super('circle_overview.leave_deletes_circle');
}
