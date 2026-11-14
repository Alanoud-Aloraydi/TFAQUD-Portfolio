import 'package:app/core/errors/failure.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:multiple_result/multiple_result.dart';

/// The home screen's day, whatever provides it.
abstract class HomeRepositoryDomain {
  Future<Result<HomeEntity, Failure>> getHome();
  String? selectedCircle(String accountId);
  Future<Result<void, Failure>> selectCircle(String accountId, String circleId);
}
