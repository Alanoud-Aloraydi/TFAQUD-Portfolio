import 'package:app/features/account/domain/usecases/profile_use_case.dart';
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

/// What the person picks on the start step.
mixin OnboardingChoice on Cubit<OnboardingState>, OnboardingScope {
  /// Picks who the care is for. Choosing [CareTarget.self] clears the
  /// follow-up question, which belongs to "another person" only.
  void selectCareTarget(CareTarget target) {
    emit(
      state.copyWith(
        careTarget: target,
        clearPatientUsesApp: target == CareTarget.self,
      ),
    );
  }

  /// Answers whether the cared-for person uses the app.
  void selectPatientUsesApp({required bool usesApp}) {
    emit(state.copyWith(patientUsesApp: usesApp));
  }
}

/// What the person types or picks on the name step.
mixin OnboardingAnswers on Cubit<OnboardingState>, OnboardingScope {
  /// Keeps the typed first name and clears any shown server error.
  void firstNameChanged(String value) {
    emit(state.copyWith(firstName: value, clearError: true));
  }

  /// Keeps the typed last name and clears any shown server error.
  void lastNameChanged(String value) {
    emit(state.copyWith(lastName: value, clearError: true));
  }

  /// Keeps the display name and clears any shown server error.
  void displayNameChanged(String value) {
    emit(state.copyWith(displayName: value, clearError: true));
  }

  /// Keeps the picked birth date and clears any shown server error.
  void birthDateChanged(DateTime value) {
    emit(state.copyWith(birthDate: value, clearError: true));
  }

  /// Keeps the picked city and clears any shown server error.
  void cityChanged(String value) {
    emit(state.copyWith(city: value, clearError: true));
  }
}
