import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/features/home/data/datasources/home_local_data_source.dart';
import 'package:app/features/home/data/datasources/home_remote_data_source.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/repositories/home_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@LazySingleton(as: HomeRepositoryDomain)
/// Provides home repository operations.
class HomeRepositoryData implements HomeRepositoryDomain {
  HomeRepositoryData(this._remote, this._local);

  final BaseHomeRemoteDataSource _remote;
  final HomeLocalDataSource _local;

  @override
  Future<Result<HomeEntity, Failure>> getHome() async {
    try {
      final HomeEntity home = (await _remote.getHome()).toEntity();
      // The words of each circle follow who is reading it.
      CareVoice.viewerName = home.displayName;
      CareVoice.update(<String, String?>{
        for (final CareCircleSummary circle in home.circles)
          circle.id: circle.isPatient ? null : circle.patientName,
      });
      return Success(home);
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
