import 'package:app/features/circles/domain/entities/account_summary.dart';
import 'package:equatable/equatable.dart';

/// The circle name chips of the person's own circle: the one for their own
/// care, or the one they agreed to. Only they see this name. [other] lets
/// them type a name.
enum NamePreset { care, health, circle, other }

/// Which circle the page creates. Each flow has its own page and its own
/// call; the health answers are filled later in the medical file.
enum CircleFlow {
  /// A circle for the person's own care (PROFILE-01): they are the patient.
  self,

  /// A circle for a patient who does not use the app (PROFILE-01B): the
  /// person types the patient's names.
  patient,

  /// The patient agreed to a request and gives the basic data (PROFILE-01C).
  /// The name comes from the account; the patient names the circle.
  approved,
}

/// Loading of the signed-in account, which gives the name shown on the
/// approved page, whether the account already has a circle of its own care
/// and the birth date and city onboarding saved.
enum AccountLoad {
  loading,
  loaded,
  failed,

  /// The [CircleFlow.patient] flow reads no account: the patient is someone
  /// else.
  notNeeded,
}

/// The progress of the create call.
enum CreateStatus { idle, saving, created }

/// State of the page that creates a circle: the circle's name, or the
/// patient's names, and the patient's birth date and city.
class CreateCircleState extends Equatable {
  const CreateCircleState({
    this.account,
    this.accountLoad = AccountLoad.loading,
    this.namePreset = NamePreset.care,
    this.customName = '',
    this.patientFirstName = '',
    this.patientLastName = '',
    this.birthDate,
    this.city,
    this.showErrors = false,
    this.status = CreateStatus.idle,
    this.errorKey,
    this.sessionEnded = false,
    this.switchToSimplified = false,
  });

  final AccountSummary? account;
  final AccountLoad accountLoad;

  /// The chosen name chip and, for [NamePreset.other], the typed name.
  final NamePreset namePreset;
  final String customName;

  /// The patient's names, typed for a patient without the app.
  final String patientFirstName;
  final String patientLastName;

  /// The birth date and city typed on the page; unused when the account
  /// holds its own ([ownBasicsSaved]).
  final DateTime? birthDate;
  final String? city;

  /// True after a tap on the create button with a missing answer.
  final bool showErrors;

  final CreateStatus status;

  /// A key in assets/translations, never a text from the server.
  final String? errorKey;

  /// True when the server said the sign-in ended; the page goes to sign-in.
  final bool sessionEnded;

  /// True right after [CircleFlow.approved] commits the account to
  /// simplified mode: the page goes to the simplified home instead of the
  /// detailed circle tab.
  final bool switchToSimplified;

  String? get fullName => account?.fullName;

  /// The account already has a circle for its own care. Nothing can be
  /// created, so the page says so before anything is filled in.
  bool get alreadyHasCircle => account?.hasOwnCircle ?? false;

  /// The page waits for the account before it can create, so it knows the
  /// birth date and city and whether a circle exists already.
  bool get waitingForAccount => accountLoad == AccountLoad.loading;

  /// The create button shows a spinner and takes no tap.
  bool get busy => waitingForAccount || status == CreateStatus.saving;

  /// Both names of the patient are typed (a circle for a patient without the
  /// app).
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

  @override
  List<Object?> get props => [
    account,
    accountLoad,
    namePreset,
    customName,
    patientFirstName,
    patientLastName,
    birthDate,
    city,
    showErrors,
    status,
    errorKey,
    sessionEnded,
    switchToSimplified,
  ];
}
