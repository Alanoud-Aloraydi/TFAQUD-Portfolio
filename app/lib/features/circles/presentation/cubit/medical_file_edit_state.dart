import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:equatable/equatable.dart';

enum MedicalFileEditStatus { loading, ready, failure }

/// What the edit page of the medical file shows: the answers as the user is
/// changing them. [file] is the file as the server last saved it, so the cubit
/// can tell what changed.
class MedicalFileEditState extends Equatable {
  const MedicalFileEditState({
    this.status = MedicalFileEditStatus.loading,
    this.file,
    this.messageKey,
    this.firstName = '',
    this.lastName = '',
    this.birthDate,
    this.city,
    this.form = const MedicalForm(),
    this.showErrors = false,
    this.saving = false,
    this.errorKey,
    this.sessionEnded = false,
  });

  final MedicalFileEditStatus status;
  final MedicalFile? file;

  /// Why the load failed: a key in assets/translations.
  final String? messageKey;

  // The basic data. The names are changed only for a patient without an
  // account; with an account they come from the account.
  final String firstName;
  final String lastName;
  final DateTime? birthDate;
  final String? city;

  // The health answers.
  final MedicalForm form;

  /// True after a tap on the save button with a missing answer.
  final bool showErrors;
  final bool saving;

  /// Why the last save failed: a key in assets/translations.
  final String? errorKey;

  /// True when the server said the sign-in ended; the page goes to sign-in.
  final bool sessionEnded;

  /// The names are typed by the managers: the patient has no account.
  bool get namesEditable => file != null && !file!.patient.hasAccount;

  bool get namesComplete =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  MedicalFileEditState copyWith({
    MedicalFileEditStatus? status,
    MedicalFile? file,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? city,
    MedicalForm? form,
    bool? showErrors,
    bool? saving,
    String? errorKey,
    bool clearError = false,
    bool? sessionEnded,
  }) {
    return MedicalFileEditState(
      status: status ?? this.status,
      file: file ?? this.file,
      messageKey: messageKey,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      form: form ?? this.form,
      showErrors: showErrors ?? this.showErrors,
      saving: saving ?? this.saving,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      sessionEnded: sessionEnded ?? this.sessionEnded,
    );
  }

  @override
  List<Object?> get props => [
    status,
    file,
    messageKey,
    firstName,
    lastName,
    birthDate,
    city,
    form,
    showErrors,
    saving,
    errorKey,
    sessionEnded,
  ];
}
