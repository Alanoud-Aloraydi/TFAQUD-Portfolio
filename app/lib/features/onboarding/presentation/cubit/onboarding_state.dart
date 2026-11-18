import 'package:app/features/onboarding/presentation/cubit/care_target.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_state_props.dart';
import 'package:app/features/onboarding/presentation/cubit/onboarding_status.dart';
import 'package:equatable/equatable.dart';

export 'package:app/features/onboarding/presentation/cubit/care_target.dart';
export 'package:app/features/onboarding/presentation/cubit/onboarding_state_copy.dart';
export 'package:app/features/onboarding/presentation/cubit/onboarding_status.dart';

/// Immutable state of `OnboardingCubit`: the answers of the name step and
/// the choice of the start step, kept while the person moves between them.
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
    this.sessionEnded = false,
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

  /// True after a tap on continue with a missing answer; turns the field
  /// errors on.
  final bool showErrors;

  final OnboardingStatus status;

  /// A key in assets/translations, never a text from the server.
  final String? errorKey;

  /// True once a save failed because the sign-in ended; the page then
  /// leaves for the sign-in.
  final bool sessionEnded;

  /// Null until the user picks.
  final CareTarget? careTarget;

  /// Only asked when [careTarget] is [CareTarget.other]. Null until picked.
  final bool? patientUsesApp;

  /// Every answer of the name step is given (names not blank).
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

  @override
  List<Object?> get props => onboardingStateProps(this);
}
