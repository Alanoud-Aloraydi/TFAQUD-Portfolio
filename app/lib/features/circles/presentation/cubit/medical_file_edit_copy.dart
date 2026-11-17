import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';

/// The same page with some answers replaced. [clearError] drops the message
/// of the save before it, and [clearTimeZone] empties the zone of a city
/// typed by hand.
extension MedicalFileEditCopy on MedicalFileEditState {
  MedicalFileEditState copyWith({
    MedicalFileEditStatus? status,
    MedicalFile? file,
    String? messageKey,
    String? firstName,
    String? lastName,
    DateTime? birthDate,
    String? city,
    String? timeZone,
    MedicalForm? form,
    bool? showErrors,
    bool? saving,
    String? errorKey,
    bool clearError = false,
    bool clearTimeZone = false,
    bool? sessionEnded,
  }) {
    return MedicalFileEditState(
      status: status ?? this.status,
      file: file ?? this.file,
      messageKey: messageKey ?? this.messageKey,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
      timeZone: clearTimeZone ? null : (timeZone ?? this.timeZone),
      form: form ?? this.form,
      showErrors: showErrors ?? this.showErrors,
      saving: saving ?? this.saving,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      sessionEnded: sessionEnded ?? this.sessionEnded,
    );
  }
}
