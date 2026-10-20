import 'package:multiple_result/multiple_result.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/onboarding/domain/entities/onboarding_entity.dart';

abstract class OnboardingRepositoryDomain {
    Future<Result<OnboardingEntity, Failure>> getOnboarding();
}
