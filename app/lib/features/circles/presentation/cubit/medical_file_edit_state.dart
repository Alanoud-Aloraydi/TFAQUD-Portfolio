export 'package:app/features/circles/presentation/cubit/medical_file_edit_status.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_props.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_status.dart';
import 'package:equatable/equatable.dart';
export 'package:app/features/circles/presentation/cubit/medical_file_edit_copy.dart';
export 'package:app/features/circles/presentation/cubit/medical_file_edit_questions.dart';

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
    this.timeZone,
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

  /// The IANA zone where the patient lives.
  final String? timeZone;

  // The health answers.
  final MedicalForm form;

  /// True after a tap on the save button with a missing answer.
  final bool showErrors;
  final bool saving;

  /// Why the last save failed: a key in assets/translations.
  final String? errorKey;

  /// True when the server said the sign-in ended; the page goes to sign-in.
  final bool sessionEnded;

  @override
  List<Object?> get props => medicalFileEditProps(this);
}
