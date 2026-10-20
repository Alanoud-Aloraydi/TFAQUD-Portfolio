import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/onboarding/data/datasources/onboarding_remote_data_source.dart';
import 'package:app/features/onboarding/domain/repositories/onboarding_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@LazySingleton(as: OnboardingRepositoryDomain)
class OnboardingRepositoryData implements OnboardingRepositoryDomain {
  OnboardingRepositoryData(this._remote);

  final BaseOnboardingRemoteDataSource _remote;

  @override
  Future<Result<bool, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
  }) async {
    try {
      await _remote.saveProfile(
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
      );
      return Success(true);
    } catch (error) {
      return Error(FailureExceptions.getException(error));
    }
  }
}
