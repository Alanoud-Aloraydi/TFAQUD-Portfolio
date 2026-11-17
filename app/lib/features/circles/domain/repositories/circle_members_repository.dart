import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:multiple_result/multiple_result.dart';

/// Reading a circle and changing who is in it.
abstract class CircleMembersRepository {
  /// Read the members and pending invitations of one circle.
  Future<Result<CircleOverview, Failure>> getCircleOverview(String circleId);

  /// Invite a manager by verified account phone number.
  Future<Result<void, Failure>> inviteManager(
    String circleId,
    String phoneNumber,
  );

  Future<Result<void, Failure>> resendManagerInvitation(
    String circleId,
    String invitationId,
  );

  Future<Result<void, Failure>> cancelManagerInvitation(
    String circleId,
    String invitationId,
  );

  /// Whether a member may edit [area] («medications», «measurements»,
  /// «appointments»); only the circle's leader may say.
  Future<Result<void, Failure>> setMemberEditAccess(
    String circleId,
    String accountId, {
    required String area,
    required bool allowed,
  });

  Future<Result<void, Failure>> removeMember(String circleId, String accountId);

  /// Hands the circle's leadership to another member.
  Future<Result<void, Failure>> handOverLeadership(
    String circleId,
    String accountId,
  );

  Future<Result<void, Failure>> leaveCircle(
    String circleId, {
    required bool confirmDelete,
  });
}
