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
