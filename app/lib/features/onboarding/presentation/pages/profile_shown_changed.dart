import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';

/// Whether [current] shows anything different from [previous].
bool profileShownChanged(OnboardingState previous, OnboardingState current) {
  bool blank(String value) => value.trim().isEmpty;
  return previous.showErrors != current.showErrors ||
      previous.status != current.status ||
      previous.errorKey != current.errorKey ||
      previous.birthDate != current.birthDate ||
      previous.city != current.city ||
      blank(previous.firstName) != blank(current.firstName) ||
      blank(previous.lastName) != blank(current.lastName) ||
      blank(previous.displayName) != blank(current.displayName);
}
