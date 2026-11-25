import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/circle_app_mode.dart';
import 'package:app/features/circles/domain/entities/circle_inbox.dart';
import 'package:app/features/circles/domain/entities/complete_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_circle_request.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/repositories/circles_repository.dart';
import 'package:app/features/circles/domain/usecases/circle_members_use_case.dart';
import 'package:app/features/circles/domain/usecases/medical_file_use_case.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';

/// The circle reads and writes the application is allowed to make.
class CirclesUseCase
    with
        CirclesUseCaseScope,
        CircleMembersUseCase,
        CircleCreationUseCase,
        CircleRequestsUseCase,
        MedicalFileUseCase {
  CirclesUseCase(this.repository);

  @override
  final CirclesRepository repository;
}

/// The account a circle starts from, creating a circle, and deleting
/// the account.
mixin CircleCreationUseCase on CirclesUseCaseScope {
  Future<Result<AccountSummary, Failure>> getAccount() =>
      repository.getAccount();

  Future<Result<CareCircleSummary, Failure>> createSelfCircle(
    NewSelfCircle circle,
  ) => repository.createSelfCircle(circle);

  Future<Result<CareCircleSummary, Failure>> createPatientCircle(
    NewPatientCircle circle,
  ) => repository.createPatientCircle(circle);

  Future<Result<void, Failure>> deleteAccount(AccountDeletion deletion) =>
      repository.deleteAccount(deletion);
}

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

/// What every part of the circles use case asks through.
mixin CirclesUseCaseScope {
  CirclesRepository get repository;
}
