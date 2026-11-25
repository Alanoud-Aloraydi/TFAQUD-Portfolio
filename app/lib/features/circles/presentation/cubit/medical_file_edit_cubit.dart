import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_form.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The edit page of the medical file (CIRCLE-05, "تعديل"): the birth date, the
/// city and its time zone, the names of a patient without an account, the
/// blood type, the chronic
/// conditions and the allergies. Each part is saved with the call of its own,
/// and only the parts that changed are sent.
class MedicalFileEditCubit extends Cubit<MedicalFileEditState> {
  MedicalFileEditCubit(this.circles, this.circleId)
    : super(const MedicalFileEditState());

  final CirclesUseCase circles;

  final String circleId;

  /// Whether the session itself ended, which the page answers by leaving.
  bool endedSession(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;

  /// A refused save: the page stops saving and says why. Always false, so a
  /// save can return it.
  bool failed(Failure failure) {
    emit(
      state.copyWith(
        saving: false,
        errorKey: failure.messageKey,
        sessionEnded: endedSession(failure),
      ),
    );
    return false;
  }

  /// Fills the page with [file], the file the medical file page already
  /// shows, so the page opens at once without reading it again.
  void start(MedicalFile file) => emit(
    MedicalFileEditState(
      status: MedicalFileEditStatus.ready,
      file: file,
      firstName: file.patient.firstName,
      lastName: file.patient.lastName,
      birthDate: file.patient.birthDate,
      city: file.patient.city,
      timeZone: file.patient.timeZone,
      form: MedicalForm.fromProfile(file.profile),
    ),
  );

  /// Reads the file and fills the page with it (when the page is opened
  /// from its address, without the file).
  Future<void> load() async {
    emit(const MedicalFileEditState());
    final result = await circles.getMedicalFile(circleId);
    if (isClosed) return;
    result.when(
      start,
      (Failure failure) => emit(
        MedicalFileEditState(
          status: MedicalFileEditStatus.failure,
          messageKey: failure.messageKey,
          sessionEnded: endedSession(failure),
        ),
      ),
    );
  }

  void firstNameChanged(String value) =>
      emit(state.copyWith(firstName: value, clearError: true));

  void lastNameChanged(String value) =>
      emit(state.copyWith(lastName: value, clearError: true));

  void birthDateChanged(DateTime value) =>
      emit(state.copyWith(birthDate: value, clearError: true));

  /// A city of the Saudi list brings its zone; a city typed by hand leaves
  /// the zone empty, to be picked ([timeZoneChanged]). Keeping the old
  /// zone would read every plan and reminder on the wrong clock.
  void cityChanged(String value) {
    final String? zone = SaudiCities.zoneOf(value);
    emit(
      state.copyWith(
        city: value,
        timeZone: zone,
        clearTimeZone: zone == null,
        clearError: true,
      ),
    );
  }

  /// The IANA zone where the patient lives, picked by hand.
  void timeZoneChanged(String value) =>
      emit(state.copyWith(timeZone: value, clearError: true));

  void chooseBloodType(String code) => _form(state.form.chooseBloodType(code));

  void toggleCondition(String code) => _form(state.form.toggleCondition(code));

  void conditionOtherChanged(String value) =>
      _form(state.form.withConditionOther(value));

  void toggleNoAllergies() => _form(state.form.toggleNoAllergies());

  void toggleMedication(String code) =>
      _form(state.form.toggleMedication(code));

  void toggleFood(String code) => _form(state.form.toggleFood(code));

  void medicationOtherChanged(String value) =>
      _form(state.form.withMedicationOther(value));

  void foodOtherChanged(String value) => _form(state.form.withFoodOther(value));

  void _form(MedicalForm form) =>
      emit(state.copyWith(form: form, clearError: true));

  /// Saves what changed. Returns true when everything the user changed is
  /// saved (or nothing changed), so the page can leave.
  ///
  /// The basic data and the health answers are two calls. When the first is
  /// saved and the second fails, the first is kept: the page keeps the
  /// answers and a second try sends only the part that failed.
  Future<bool> save() async {
    final MedicalFile? file = state.file;
    final DateTime? birthDate = state.birthDate;
    final String? city = state.city;
    if (file == null || state.saving) return false;
    if ((state.namesEditable && !state.namesComplete) ||
        birthDate == null ||
        city == null ||
        state.zoneMissing ||
        !state.form.conditionsValid ||
        !state.form.allergiesValid) {
      emit(state.copyWith(showErrors: true));
      return false;
    }
    final MedicalFileChanges changes = MedicalFileChanges(
      state,
      file,
      birthDate: birthDate,
      city: city,
    );
    if (!changes.basicsChanged && !changes.profileChanged) return true;

    emit(state.copyWith(saving: true, showErrors: false, clearError: true));
    MedicalFile saved = file;

    if (changes.basicsChanged) {
      final result = await circles.updatePatient(circleId, changes.update);
      if (isClosed) return false;
      if (result.isError()) return failed(result.tryGetError()!);
      saved = saved.copyWith(patient: changes.patient);
      emit(state.copyWith(file: saved));
      // Kept even when the health answers fail next.
      circles.medicalFileSaved(circleId, saved);
    }

    if (changes.profileChanged) {
      final result = await circles.updateMedicalProfile(
        circleId,
        changes.profile,
      );
      if (isClosed) return false;
      if (result.isError()) return failed(result.tryGetError()!);
      saved = saved.copyWith(profile: result.tryGetSuccess()!);
      circles.medicalFileSaved(circleId, saved);
    }

    emit(state.copyWith(file: saved, saving: false));
    return true;
  }
}

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
