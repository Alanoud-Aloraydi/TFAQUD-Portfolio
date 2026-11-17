import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/patient_update.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';

/// What the edit page changed against the saved [MedicalFile], worked out
/// once before saving: which of the two calls are needed, and what each
/// sends.
class MedicalFileChanges {
  MedicalFileChanges(
    MedicalFileEditState state,
    MedicalFile file, {
    required DateTime birthDate,
    required String city,
  }) : profile = state.form.toProfile() {
    final PatientBasics before = file.patient;
    final bool editNames = state.namesEditable;
    final String firstName = editNames ? state.firstName.trim() : '';
    final String lastName = editNames ? state.lastName.trim() : '';
    final bool cityChanged = city != before.city;
    final String timeZone =
        state.timeZone ?? SaudiCities.zoneOf(city) ?? before.timeZone;
    basicsChanged =
        birthDate != before.birthDate ||
        cityChanged ||
        timeZone != before.timeZone ||
        (editNames &&
            (firstName != before.firstName || lastName != before.lastName));
    profileChanged = profile != file.profile;
    patient = PatientBasics(
      firstName: editNames ? firstName : before.firstName,
      lastName: editNames ? lastName : before.lastName,
      birthDate: birthDate,
      city: city,
      hasAccount: before.hasAccount,
      // The coordinates of an old city would be wrong for the new one.
      latitude: cityChanged ? null : before.latitude,
      longitude: cityChanged ? null : before.longitude,
      timeZone: timeZone,
    );
    update = PatientUpdate(
      birthDate: birthDate,
      city: city,
      firstName: editNames ? firstName : null,
      lastName: editNames ? lastName : null,
      latitude: patient.latitude,
      longitude: patient.longitude,
      timeZone: timeZone,
    );
  }

  /// The health answers to save.
  final MedicalProfileDraft profile;

  /// The patient as the page will show them once the basic data is saved.
  late final PatientBasics patient;

  /// The body of the call that saves the basic data.
  late final PatientUpdate update;

  late final bool basicsChanged;
  late final bool profileChanged;
}
