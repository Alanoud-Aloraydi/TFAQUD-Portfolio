import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/domain/entities/new_self_circle.dart';
import 'package:app/features/circles/domain/repositories/circles_repository_domain.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@lazySingleton
class CirclesUseCase {
  CirclesUseCase(this._repository);

  final CirclesRepositoryDomain _repository;

  Future<Result<AccountSummary, Failure>> getAccount() =>
      _repository.getAccount();

  Future<Result<CareCircleSummary, Failure>> createSelfCircle(
    NewSelfCircle circle,
  ) => _repository.createSelfCircle(circle);
}
