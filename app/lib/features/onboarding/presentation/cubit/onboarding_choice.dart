import 'package:app/features/onboarding/presentation/cubit/onboarding_scope.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
