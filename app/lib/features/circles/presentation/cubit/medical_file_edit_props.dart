import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';

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
