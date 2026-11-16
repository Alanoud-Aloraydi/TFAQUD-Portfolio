part of '../circles_remote_data_source.dart';

/// A circle's managers: inviting them, what they may edit, and who leads.
abstract interface class CircleMemberApi {
  /// POST /api/v1/circles/{id}/invitations.
  Future<void> inviteManager(String circleId, String phoneNumber);

  Future<void> resendManagerInvitation(String circleId, String invitationId);

  Future<void> cancelManagerInvitation(String circleId, String invitationId);

  /// PATCH /api/v1/circles/{id}/members/{account}: whether the member may
  /// edit [area] («medications», «measurements», «appointments»).
  Future<void> setMemberEditAccess(
    String circleId,
    String accountId, {
    required String area,
    required bool allowed,
  });

  Future<void> removeMember(String circleId, String accountId);

  /// PUT /api/v1/circles/{id}/leader.
  Future<void> handOverLeadership(String circleId, String accountId);

  Future<void> leaveCircle(String circleId, {required bool confirmDelete});
}
