import 'package:app/core/errors/failure.dart';
import 'package:app/features/onboarding/domain/repositories/onboarding_repository_domain.dart';
import 'package:injectable/injectable.dart';
import 'package:multiple_result/multiple_result.dart';

@lazySingleton
class OnboardingUseCase {
  OnboardingUseCase(this._repository);

  final OnboardingRepositoryDomain _repository;

  Future<Result<bool, Failure>> saveProfile({
    required String firstName,
    required String lastName,
    required String displayName,
  }) {
    return _repository.saveProfile(
      firstName: firstName,
      lastName: lastName,
      displayName: displayName,
    );
  }
}
