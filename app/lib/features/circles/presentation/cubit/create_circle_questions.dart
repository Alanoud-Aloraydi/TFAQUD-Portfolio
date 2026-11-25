import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:app/features/circles/presentation/cubit/create_circle_state.dart';

/// What the page asks, and what it already knows from the account.
extension CreateCircleQuestions on CreateCircleState {
  String? get fullName => account?.fullName;

  /// The account already has a circle for its own care. Nothing can be
  /// created, so the page says so before anything is filled in.
  bool get alreadyHasCircle => account?.hasOwnCircle ?? false;

  /// The page waits for the account before it can create, so it knows the
  /// birth date and city and whether a circle exists already.
  bool get waitingForAccount => accountLoad == AccountLoad.loading;

  /// The create button shows a spinner and takes no tap.
  bool get busy => waitingForAccount || status == CreateStatus.saving;

  /// Both names of the patient are typed (a circle for a patient without
  /// the app).
  bool get patientNamesComplete =>
      patientFirstName.trim().isNotEmpty && patientLastName.trim().isNotEmpty;

  /// The account already holds the birth date and city from onboarding, so
  /// a circle for its own care does not ask for them.
  bool get ownBasicsSaved => account?.hasBasics ?? false;

  /// The page asks for the birth date and city: always for a patient without
  /// the app, and for the person's own care only when the account has not
  /// saved them (or could not be read).
  bool get asksBasics => !ownBasicsSaved;

  /// The patient's birth date: the account's when it holds one, else the one
  /// typed on the page.
  DateTime? get patientBirthDate =>
      ownBasicsSaved ? account!.birthDate : birthDate;

  /// The patient's city, the same way. It also gives the patient's zone.
  String? get patientCity => ownBasicsSaved ? account!.city : city;
}

/// The same page with one answer changed; [clearError] drops the message of
/// the try before it.
extension CreateCircleCopy on CreateCircleState {
  CreateCircleState copyWith({
    AccountSummary? account,
    AccountLoad? accountLoad,
    NamePreset? namePreset,
    String? customName,
    String? patientFirstName,
    String? patientLastName,
    DateTime? birthDate,
    String? city,
    bool? showErrors,
    CreateStatus? status,
    String? errorKey,
    bool clearError = false,
    bool? sessionEnded,
    bool? switchToSimplified,
  }) {
    return CreateCircleState(
      account: account ?? this.account,
      accountLoad: accountLoad ?? this.accountLoad,
      namePreset: namePreset ?? this.namePreset,
      customName: customName ?? this.customName,
      patientFirstName: patientFirstName ?? this.patientFirstName,
      patientLastName: patientLastName ?? this.patientLastName,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      showErrors: showErrors ?? this.showErrors,
      status: status ?? this.status,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      sessionEnded: sessionEnded ?? this.sessionEnded,
      switchToSimplified: switchToSimplified ?? this.switchToSimplified,
    );
  }
}

/// What makes two [CreateCircleState]s equal: every field, in the order the
/// class declares them.
List<Object?> createCircleProps(CreateCircleState state) => <Object?>[
  state.account,
  state.accountLoad,
  state.namePreset,
  state.customName,
  state.patientFirstName,
  state.patientLastName,
  state.birthDate,
  state.city,
  state.showErrors,
  state.status,
  state.errorKey,
  state.sessionEnded,
  state.switchToSimplified,
];
