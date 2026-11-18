import 'package:app/features/account/domain/use_cases/profile_use_case.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_answers.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_choice.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_saving.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_scope.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Presentation logic of the first account set-up (onboarding).
///
/// Flow: `ProfileStepScreen` and `StartScreen` → this cubit →
/// [ProfileUseCase] → PUT /api/v1/accounts/me/profile → the `account`
/// table. One instance lives in the onboarding `ShellRoute`, so the name
/// step and the start step share the typed answers and the choice.
class OnboardingCubit extends Cubit<OnboardingState>
    with
        OnboardingScope,
        OnboardingAnswers,
        OnboardingSaving,
        OnboardingChoice {
  OnboardingCubit(this.profile) : super(const OnboardingState());

  @override
  final ProfileUseCase profile;
}
