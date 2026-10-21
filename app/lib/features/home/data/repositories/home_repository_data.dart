import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/home/data/datasources/home_local_data_source.dart';
import 'package:app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/repositories/home_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@LazySingleton(as: HomeRepositoryDomain)
class HomeRepositoryData implements HomeRepositoryDomain {
  HomeRepositoryData(this._remote, this._local);

  final BaseHomeRemoteDataSource _remote;
  final HomeLocalDataSource _local;

  @override
  Future<Result<HomeEntity, Failure>> getHome() async {
    try {
      return Success((await _remote.getHome()).toEntity());
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }

  @override
  String? selectedCircle(String accountId) {
    try {
      return _local.selectedCircle(accountId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Result<void, Failure>> selectCircle(
    String accountId,
    String circleId,
  ) async {
    try {
      await _local.selectCircle(accountId, circleId);
      return const Success(null);
    } catch (_) {
      return const Error(CacheFailure('home.selection_failed'));
    }
  }
}
