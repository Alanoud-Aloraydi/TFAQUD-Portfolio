import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/repositories/circles_repository_domain.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

/// A circles repository that answers from memory and records what it was asked
/// to create.
class CirclesFakeRepository extends Fake implements CirclesRepositoryDomain {
  static const AccountSummary reem = AccountSummary(
    firstName: 'Reem',
    lastName: 'Alahmadi',
  );
  static const CareCircleSummary newCircle = CareCircleSummary(
    id: 'new-circle',
    name: 'My care',
  );

  Result<AccountSummary, Failure> account = const Success(reem);
  Result<CareCircleSummary, Failure> created = const Success(newCircle);

  /// When set, a create call waits for it, so a test can act in between.
  Future<Result<CareCircleSummary, Failure>>? pending;

  final List<NewSelfCircle> requests = <NewSelfCircle>[];

  void reset() {
    account = const Success(reem);
    created = const Success(newCircle);
    pending = null;
    requests.clear();
  }

  @override
  Future<Result<AccountSummary, Failure>> getAccount() async => account;

  @override
  Future<Result<CareCircleSummary, Failure>> createSelfCircle(
    NewSelfCircle circle,
  ) async {
    requests.add(circle);
    return pending ?? created;
  }
}
