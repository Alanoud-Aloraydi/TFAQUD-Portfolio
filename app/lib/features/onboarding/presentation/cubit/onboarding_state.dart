import 'package:equatable/equatable.dart';

/// Defines the supported onboarding status values.
enum OnboardingStatus { idle, saving, saved }

/// Who the care circle is for (page "كيف تريد أن تبدأ؟").
enum CareTarget { self, other }

/// State of the account setup pages («About you», then how to start).
class OnboardingState extends Equatable {
  const OnboardingState({
    this.firstName = '',
    this.lastName = '',
    this.displayName = '',
    this.birthDate,
    this.city,
    this.showErrors = false,
    this.status = OnboardingStatus.idle,
    this.errorKey,
    this.careTarget,
    this.patientUsesApp,
  });

  final String firstName;
  final String lastName;
  final String displayName;

  /// The person's own birth date and city: asked once here, so a circle for
  /// their own care needs only its name.
  final DateTime? birthDate;
  final String? city;

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
      displayName.trim().isNotEmpty &&
      birthDate != null &&
      city != null;

  /// The start page may continue once the choice is complete.
  bool get canContinueStart =>
      careTarget == CareTarget.self ||
      (careTarget == CareTarget.other && patientUsesApp != null);

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
    birthDate,
    city,
    showErrors,
    status,
    errorKey,
    careTarget,
    patientUsesApp,
  ];
}
