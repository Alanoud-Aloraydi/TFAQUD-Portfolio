import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_form.dart';
import 'package:equatable/equatable.dart';

export 'package:app/features/circles/presentation/cubit/medical_file_edit_copy.dart';

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

enum MedicalFileEditStatus { loading, ready, failure }

/// What makes two [MedicalFileEditState]s equal: every field, in the order the
/// class declares them.
List<Object?> medicalFileEditProps(MedicalFileEditState state) => <Object?>[
  state.status,
  state.file,
  state.messageKey,
  state.firstName,
  state.lastName,
  state.birthDate,
  state.city,
  state.timeZone,
  state.form,
  state.showErrors,
  state.saving,
  state.errorKey,
  state.sessionEnded,
];

/// What the edit page asks about the patient's names and zone.
extension MedicalFileEditQuestions on MedicalFileEditState {
  /// The names are typed by the managers: the patient has no account.
  bool get namesEditable => file != null && !file!.patient.hasAccount;

  bool get namesComplete =>
      firstName.trim().isNotEmpty && lastName.trim().isNotEmpty;

  /// The «المنطقة الزمنية» row shows for every city outside the Saudi
  /// list: a listed city brings Saudi Arabia's zone ([SaudiCities.zoneOf]),
  /// any other city needs the zone said out loud, because every reminder,
  /// plan and reading of the circle is read on it.
  bool get zoneEditable => city != null && SaudiCities.zoneOf(city) == null;

  /// Whether the zone is still missing for a city that needs one.
  bool get zoneMissing => zoneEditable && timeZone == null;
}
