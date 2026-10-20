import 'package:app/features/onboarding/data/models/onboarding_model.dart';
import 'package:injectable/injectable.dart';

abstract class BaseOnboardingRemoteDataSource {
  Future<OnboardingModel> getOnboarding();
}

/// Placeholder data. The real profile calls are written with TFQD-22.
@LazySingleton(as: BaseOnboardingRemoteDataSource)
class OnboardingRemoteDataSource implements BaseOnboardingRemoteDataSource {
  @override
  Future<OnboardingModel> getOnboarding() async {
    return OnboardingModel(
      id: 1,
      firstName: 'Last Name',
      lastName: 'First Name',
    );
  }
}
