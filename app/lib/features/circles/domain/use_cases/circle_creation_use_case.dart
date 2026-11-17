import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/account_deletion.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_patient_circle.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case_scope.dart';

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
