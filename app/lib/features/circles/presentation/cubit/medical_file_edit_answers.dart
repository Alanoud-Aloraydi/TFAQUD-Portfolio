import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_scope.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
