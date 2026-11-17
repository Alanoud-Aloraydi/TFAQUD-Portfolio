import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case_scope.dart';

/// The requests and invitations between people.
mixin CircleRequestsUseCase on CirclesUseCaseScope {
  Future<Result<SentCircleRequest, Failure>> sendCircleRequest(
    NewCircleRequest request,
  ) => repository.sendCircleRequest(request);

  Future<Result<CircleInbox, Failure>> getInbox() => repository.getInbox();

  Future<Result<CircleRequestStatus, Failure>> respondToRequest(
    String id, {
    required bool accept,
  }) => repository.respondToRequest(id, accept: accept);

  Future<Result<String?, Failure>> respondToInvitation(
    String id, {
    required bool accept,
  }) => repository.respondToInvitation(id, accept: accept);

  Future<Result<(CareCircleSummary, CircleAppMode), Failure>> completeRequest(
    String id,
    CompleteCircleRequest request,
  ) => repository.completeRequest(id, request);

  Future<Result<void, Failure>> cancelRequest(String id) =>
      repository.cancelRequest(id);
}
