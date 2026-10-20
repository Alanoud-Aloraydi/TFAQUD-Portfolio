import 'package:multiple_result/multiple_result.dart';
import 'package:injectable/injectable.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/onboarding/domain/entities/onboarding_entity.dart';
import 'package:app/features/onboarding/domain/repositories/onboarding_repository_domain.dart';


@lazySingleton
class OnboardingUseCase {
  final OnboardingRepositoryDomain _repositoryData;

  OnboardingUseCase(this._repositoryData);

   Future<Result<OnboardingEntity, Failure>> getOnboarding() async {
    return _repositoryData.getOnboarding();
  }
}
