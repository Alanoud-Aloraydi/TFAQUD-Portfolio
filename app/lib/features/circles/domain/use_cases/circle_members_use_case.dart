import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case_scope.dart';

/// Reading a circle, naming it, and changing who is in it.
mixin CircleMembersUseCase on CirclesUseCaseScope {
  Future<Result<CircleOverview, Failure>> getCircleOverview(String circleId) =>
      repository.getCircleOverview(circleId);

  Future<Result<void, Failure>> renameCircle(String circleId, String name) =>
      repository.renameCircle(circleId, name);

  Future<Result<void, Failure>> inviteManager(
    String circleId,
    String phoneNumber,
  ) => repository.inviteManager(circleId, phoneNumber);

  Future<Result<void, Failure>> resendManagerInvitation(
    String circleId,
    String invitationId,
  ) => repository.resendManagerInvitation(circleId, invitationId);

  Future<Result<void, Failure>> cancelManagerInvitation(
    String circleId,
    String invitationId,
  ) => repository.cancelManagerInvitation(circleId, invitationId);

  Future<Result<void, Failure>> setMemberEditAccess(
    String circleId,
    String accountId, {
    required String area,
    required bool allowed,
  }) => repository.setMemberEditAccess(
    circleId,
    accountId,
    area: area,
    allowed: allowed,
  );

  Future<Result<void, Failure>> handOverLeadership(
    String circleId,
    String accountId,
  ) => repository.handOverLeadership(circleId, accountId);

  Future<Result<void, Failure>> removeMember(
    String circleId,
    String accountId,
  ) => repository.removeMember(circleId, accountId);

  Future<Result<void, Failure>> leaveCircle(
    String circleId, {
    required bool confirmDelete,
  }) => repository.leaveCircle(circleId, confirmDelete: confirmDelete);
}
