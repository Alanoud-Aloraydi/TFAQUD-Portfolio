import 'package:app/core/errors/failure.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/domain/repositories/home_repository_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_result/multiple_result.dart';

HomeEntity homeData({
  String accountId = 'account-a',
  bool profileComplete = true,
  List<CareCircleSummary> circles = const [
    CareCircleSummary(id: 'one', name: 'Circle one'),
    CareCircleSummary(id: 'two', name: 'Circle two'),
  ],
}) => HomeEntity(
  accountId: accountId,
  displayName: 'Nora',
  profileComplete: profileComplete,
  circles: circles,
);

class HomeFakeRepository extends Fake implements HomeRepositoryDomain {
  Result<HomeEntity, Failure> response = Success(homeData());
  Future<Result<HomeEntity, Failure>>? pending;
  final selections = <String, String>{};
  bool saveFails = false;

  @override
  Future<Result<HomeEntity, Failure>> getHome() async => pending ?? response;

  @override
  String? selectedCircle(String accountId) => selections[accountId];

  @override
  Future<Result<void, Failure>> selectCircle(
    String accountId,
    String circleId,
  ) async {
    if (saveFails) return const Error(CacheFailure('home.selection_failed'));
    selections[accountId] = circleId;
    return const Success(null);
  }
}
