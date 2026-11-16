part of '../circles_remote_data_source.dart';

/// The calls for a circle's managers and members.
mixin _MemberRequests implements CircleMemberApi {
  DioClient get _client;

  @override
  Future<void> inviteManager(String circleId, String phoneNumber) async {
    await _client.post(
      ApiEndpoints.circleInvitations(circleId),
      data: <String, String>{'invitee_phone_number': phoneNumber},
    );
  }

  @override
  Future<void> resendManagerInvitation(
    String circleId,
    String invitationId,
  ) async {
    await _client.post(
      ApiEndpoints.resendCircleInvitation(circleId, invitationId),
    );
  }

  @override
  Future<void> cancelManagerInvitation(
    String circleId,
    String invitationId,
  ) async {
    await _client.delete(ApiEndpoints.circleInvitation(circleId, invitationId));
  }

  @override
  Future<void> setMemberEditAccess(
    String circleId,
    String accountId, {
    required String area,
    required bool allowed,
  }) async {
    await _client.patch(
      ApiEndpoints.circleMember(circleId, accountId),
      data: <String, Object>{
        'edit_access': <String, bool>{area: allowed},
      },
    );
  }

  @override
  Future<void> handOverLeadership(String circleId, String accountId) async {
    await _client.put(
      ApiEndpoints.circleLeader(circleId),
      data: <String, String>{'account_id': accountId},
    );
  }

  @override
  Future<void> removeMember(String circleId, String accountId) async {
    await _client.delete(ApiEndpoints.circleMember(circleId, accountId));
  }

  @override
  Future<void> leaveCircle(
    String circleId, {
    required bool confirmDelete,
  }) async {
    await _client.post(
      ApiEndpoints.leaveCircle(circleId),
      data: <String, bool>{'confirm_delete': confirmDelete},
    );
  }
}
