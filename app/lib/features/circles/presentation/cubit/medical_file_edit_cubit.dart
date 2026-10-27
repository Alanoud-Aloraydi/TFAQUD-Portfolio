import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_profile_draft.dart';
import 'package:app/features/circles/domain/entities/patient_update.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/domain/use_cases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The edit page of the medical file (CIRCLE-05, "تعديل"): the birth date, the
/// city, the names of a patient without an account, the blood type, the chronic
/// conditions and the allergies. Each part is saved with the call of its own,
/// and only the parts that changed are sent.
class MedicalFileEditCubit extends Cubit<MedicalFileEditState> {
  MedicalFileEditCubit(this._circles, this.circleId)
    : super(const MedicalFileEditState());

  final CirclesUseCase _circles;
  final String circleId;

  /// The longest first name or last name of a patient the API accepts.
  static const int maxNameLength = 50;

  /// Reads the file and fills the page with it.
  Future<void> load() async {
    emit(const MedicalFileEditState());
    final result = await _circles.getMedicalFile(circleId);
    if (isClosed) return;
    result.when(
      (MedicalFile file) => emit(
        MedicalFileEditState(
          status: MedicalFileEditStatus.ready,
          file: file,
          firstName: file.patient.firstName,
          lastName: file.patient.lastName,
          birthDate: file.patient.birthDate,
          city: file.patient.city,
          form: MedicalForm.fromProfile(file.profile),
        ),
      ),
      (Failure failure) => emit(
        MedicalFileEditState(
          status: MedicalFileEditStatus.failure,
          messageKey: failure.messageKey,
          sessionEnded: _ended(failure),
        ),
      ),
    );
  }

  // ---- the basic data --------------------------------------------------

  void firstNameChanged(String value) =>
      emit(state.copyWith(firstName: value, clearError: true));

  void lastNameChanged(String value) =>
      emit(state.copyWith(lastName: value, clearError: true));

  void birthDateChanged(DateTime value) =>
      emit(state.copyWith(birthDate: value, clearError: true));

  void cityChanged(String value) =>
      emit(state.copyWith(city: value, clearError: true));

  // ---- the health answers ----------------------------------------------

  void chooseBloodType(String code) => _form(state.form.chooseBloodType(code));

  void toggleCondition(String code) =>
      _form(state.form.toggleCondition(code));

  void conditionOtherChanged(String value) =>
      _form(state.form.withConditionOther(value));

  void toggleNoAllergies() => _form(state.form.toggleNoAllergies());

  void toggleMedication(String code) =>
      _form(state.form.toggleMedication(code));

  void toggleFood(String code) => _form(state.form.toggleFood(code));

  void medicationOtherChanged(String value) =>
      _form(state.form.withMedicationOther(value));

  void foodOtherChanged(String value) =>
      _form(state.form.withFoodOther(value));

  void _form(MedicalForm form) =>
      emit(state.copyWith(form: form, clearError: true));

  // ---- save ------------------------------------------------------------

  /// Saves what changed. Returns true when everything the user changed is
  /// saved (or nothing changed), so the page can leave.
  ///
  /// The basic data and the health answers are two calls. When the first is
  /// saved and the second fails, the first is kept: the page keeps the answers
  /// and a second try sends only the part that failed.
  Future<bool> save() async {
    final MedicalFile? file = state.file;
    final DateTime? birthDate = state.birthDate;
    final String? city = state.city;
    if (file == null || state.saving) return false;
    if ((state.namesEditable && !state.namesComplete) ||
        birthDate == null ||
        city == null ||
        !state.form.conditionsValid ||
        !state.form.allergiesValid) {
      emit(state.copyWith(showErrors: true));
      return false;
    }
    final PatientBasics patient = file.patient;
    final bool editNames = state.namesEditable;
    final String firstName = editNames ? state.firstName.trim() : '';
    final String lastName = editNames ? state.lastName.trim() : '';
    final bool cityChanged = city != patient.city;
    final bool basicsChanged =
        birthDate != patient.birthDate ||
        cityChanged ||
        (editNames &&
            (firstName != patient.firstName || lastName != patient.lastName));
    final MedicalProfileDraft profile = state.form.toProfile();
    final bool profileChanged = profile != file.profile;
    if (!basicsChanged && !profileChanged) return true;

    emit(state.copyWith(saving: true, showErrors: false, clearError: true));
    MedicalFile saved = file;

    if (basicsChanged) {
      final PatientBasics updated = PatientBasics(
        firstName: editNames ? firstName : patient.firstName,
        lastName: editNames ? lastName : patient.lastName,
        birthDate: birthDate,
        city: city,
        hasAccount: patient.hasAccount,
        // The coordinates of an old city would be wrong for the new one.
        latitude: cityChanged ? null : patient.latitude,
        longitude: cityChanged ? null : patient.longitude,
      );
      final result = await _circles.updatePatient(
        circleId,
        PatientUpdate(
          birthDate: birthDate,
          city: city,
          firstName: editNames ? firstName : null,
          lastName: editNames ? lastName : null,
          latitude: updated.latitude,
          longitude: updated.longitude,
        ),
      );
      if (isClosed) return false;
      if (result.isError()) return _failed(result.tryGetError()!);
      saved = saved.copyWith(patient: updated);
      emit(state.copyWith(file: saved));
    }

    if (profileChanged) {
      final result = await _circles.updateMedicalProfile(circleId, profile);
      if (isClosed) return false;
      if (result.isError()) return _failed(result.tryGetError()!);
      saved = saved.copyWith(profile: result.tryGetSuccess()!);
    }

    emit(state.copyWith(file: saved, saving: false));
    return true;
  }

  bool _failed(Failure failure) {
    emit(
      state.copyWith(
        saving: false,
        errorKey: failure.messageKey,
        sessionEnded: _ended(failure),
      ),
    );
    return false;
  }

  bool _ended(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}
