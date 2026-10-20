import 'package:equatable/equatable.dart';

enum OnboardingStatus { idle, saving, saved }

/// Who the care circle is for (page "كيف تريد أن تبدأ؟").
enum CareTarget { self, other }

/// State of the account setup pages (name, then how to start).
class OnboardingState extends Equatable {
  const OnboardingState({
    this.firstName = '',
    this.lastName = '',
    this.displayName = '',
    this.showErrors = false,
    this.status = OnboardingStatus.idle,
    this.errorKey,
    this.careTarget,
    this.patientUsesApp,
  });

  final String firstName;
  final String lastName;
  final String displayName;

  /// True after a tap on continue with an empty field.
  final bool showErrors;

  final OnboardingStatus status;

  /// A key in assets/translations, never a text from the server.
  final String? errorKey;

  /// Null until the user picks.
  final CareTarget? careTarget;

  /// Only asked when [careTarget] is [CareTarget.other]. Null until picked.
  final bool? patientUsesApp;

  bool get isProfileValid =>
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      displayName.trim().isNotEmpty;

  /// The start page may continue once the choice is complete.
  bool get canContinueStart =>
      careTarget == CareTarget.self ||
      (careTarget == CareTarget.other && patientUsesApp != null);

  OnboardingState copyWith({
    String? firstName,
    String? lastName,
    String? displayName,
    bool? showErrors,
    OnboardingStatus? status,
    String? errorKey,
    bool clearError = false,
    CareTarget? careTarget,
    bool? patientUsesApp,
    bool clearPatientUsesApp = false,
  }) {
    return OnboardingState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      displayName: displayName ?? this.displayName,
      showErrors: showErrors ?? this.showErrors,
      status: status ?? this.status,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      careTarget: careTarget ?? this.careTarget,
      patientUsesApp: clearPatientUsesApp
          ? null
          : (patientUsesApp ?? this.patientUsesApp),
    );
  }

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    displayName,
    showErrors,
    status,
    errorKey,
    careTarget,
    patientUsesApp,
  ];
}
