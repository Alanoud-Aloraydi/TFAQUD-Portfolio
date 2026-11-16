import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_acting.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_scope.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What a circle's leader can do about its members: invite, invite again,
/// take an invitation back, say what a member may edit, hand the circle
/// over, remove a member, and leave.
mixin CircleMemberActions
    on Cubit<CircleOverviewState>, CircleOverviewScope, CircleOverviewActing {
  /// Invites [nationalNumber] to manage the circle. Returns an error key,
  /// or null once the invitation is saved and the list read again.
  Future<String?> invite(String nationalNumber) async {
    if (!SaudiMobile.isValid(nationalNumber)) {
      return 'circle_overview.phone_invalid';
    }
    return act(
      () => circles.inviteManager(
        circleId,
        SaudiMobile.international(nationalNumber),
      ),
    );
  }

  /// Sends a pending invitation again. Returns an error key, or null.
  Future<String?> resendInvitation(String invitationId) =>
      act(() => circles.resendManagerInvitation(circleId, invitationId));

  /// Cancels a pending invitation. Returns an error key, or null.
  Future<String?> cancelInvitation(String invitationId) =>
      act(() => circles.cancelManagerInvitation(circleId, invitationId));

  /// Lets a member edit [area] or not. Returns an error key, or null.
  Future<String?> setMemberEditAccess(
    String accountId, {
    required String area,
    required bool allowed,
  }) => act(
    () => circles.setMemberEditAccess(
      circleId,
      accountId,
      area: area,
      allowed: allowed,
    ),
  );

  /// Hands the circle's leadership to a member. Returns an error key, or
  /// null.
  Future<String?> handOverLeadership(String accountId) =>
      act(() => circles.handOverLeadership(circleId, accountId));

  /// Removes a member from the circle. Returns an error key, or null.
  Future<String?> removeMember(String accountId) =>
      act(() => circles.removeMember(circleId, accountId));

  /// Leaves the circle; [confirmDelete] agrees that the circle is deleted
  /// ([CircleOverview.leaveDeletesCircle]). Returns an error key, or null
  /// once the person is out. The circle is not read again after a success:
  /// the person can no longer read it.
  Future<String?> leave({required bool confirmDelete}) => act(
    () => circles.leaveCircle(circleId, confirmDelete: confirmDelete),
    reload: false,
  );
}
