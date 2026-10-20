import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app/features/onboarding/domain/use_cases/onboarding_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final OnboardingUseCase _onboardingUseCase;

  OnboardingCubit(this._onboardingUseCase) : super(OnboardingInitialState());

  Future<void> getOnboardingMethod() async {
    final result = await _onboardingUseCase.getOnboarding();
    result.when(
      (success) {
        //here is when success result
      },
      (whenError) {
       //here is when error result
      },
    );
  }

  @override
  Future<void> close() {
    //here is when close cubit
    return super.close();
  }
}
