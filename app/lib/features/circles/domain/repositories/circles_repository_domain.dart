import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';

abstract class CirclesRepositoryDomain {
  /// The signed-in account: GET /api/v1/accounts/me.
  Future<Result<AccountSummary, Failure>> getAccount();

  /// Creates the circle of the signed-in person for their own care:
  /// POST /api/v1/circles/self. Returns the new circle.
  Future<Result<CareCircleSummary, Failure>> createSelfCircle(
    NewSelfCircle circle,
  );
}
