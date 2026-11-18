import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';

/// What makes two [OnboardingState]s equal: every field, in the order the
/// class declares them.
List<Object?> onboardingStateProps(OnboardingState state) => <Object?>[
  state.firstName,
  state.lastName,
  state.displayName,
  state.birthDate,
  state.city,
  state.showErrors,
  state.status,
  state.errorKey,
  state.sessionEnded,
  state.careTarget,
  state.patientUsesApp,
];
