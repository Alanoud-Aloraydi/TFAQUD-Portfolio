import 'package:app/features/onboarding/presentation/cubit/onboarding_state.dart';

/// A changed copy of an [OnboardingState].
extension OnboardingStateCopy on OnboardingState {
  /// A copy with the given values. [clearError] drops [errorKey];
  /// [clearPatientUsesApp] drops [patientUsesApp].
  OnboardingState copyWith({
    String? firstName,
    String? lastName,
    String? displayName,
    DateTime? birthDate,
    String? city,
    bool? showErrors,
    OnboardingStatus? status,
    String? errorKey,
    bool clearError = false,
    bool? sessionEnded,
    CareTarget? careTarget,
    bool? patientUsesApp,
    bool clearPatientUsesApp = false,
  }) {
    return OnboardingState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      showErrors: showErrors ?? this.showErrors,
      status: status ?? this.status,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      sessionEnded: sessionEnded ?? this.sessionEnded,
      careTarget: careTarget ?? this.careTarget,
      patientUsesApp: clearPatientUsesApp
          ? null
          : (patientUsesApp ?? this.patientUsesApp),
    );
  }
}
