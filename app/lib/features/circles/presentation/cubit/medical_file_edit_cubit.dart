import 'package:app/core/constants/saudi_cities.dart';
import 'package:app/features/circles/domain/entities/medical_form.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_saving.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The edit page of the medical file (CIRCLE-05, "تعديل"): the birth date, the
/// city and its time zone, the names of a patient without an account, the
/// blood type, the chronic
/// conditions and the allergies. Each part is saved with the call of its own,
/// and only the parts that changed are sent.
class MedicalFileEditCubit extends Cubit<MedicalFileEditState>
    with
        MedicalFileEditScope,
        MedicalFileEditLoading,
        MedicalFileEditBasics,
        MedicalFileEditAnswers,
        MedicalFileEditSaving {
  MedicalFileEditCubit(this.circles, this.circleId)
    : super(const MedicalFileEditState());

  @override
  final CirclesUseCase circles;

  @override
  final String circleId;
}

/// The health answers as they are tapped: the blood type, the chronic
/// conditions and the allergies. The rules of each tap are [MedicalForm]'s.
mixin MedicalFileEditAnswers
    on Cubit<MedicalFileEditState>, MedicalFileEditScope {
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
}

/// The patient's basic data as it is typed: the names, the birth date, the
/// city and its zone.
mixin MedicalFileEditBasics
    on Cubit<MedicalFileEditState>, MedicalFileEditScope {
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
}
