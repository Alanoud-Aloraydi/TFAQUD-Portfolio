import 'package:app/core/errors/failure.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';

/// Provides home domain operations.
abstract class HomeRepositoryDomain {
  Future<Result<HomeEntity, Failure>> getHome();
  String? selectedCircle(String accountId);
  Future<Result<void, Failure>> selectCircle(String accountId, String circleId);
}
