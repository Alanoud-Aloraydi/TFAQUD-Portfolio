import 'package:app/core/errors/failure.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/repositories/home_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@lazySingleton
class HomeUseCase {
  HomeUseCase(this._repository);

  final HomeRepositoryDomain _repository;

  Future<Result<HomeEntity, Failure>> getHome() => _repository.getHome();

  String? selectedCircle(String accountId) =>
      _repository.selectedCircle(accountId);

  Future<Result<void, Failure>> selectCircle(
    String accountId,
    String circleId,
  ) => _repository.selectCircle(accountId, circleId);
}
