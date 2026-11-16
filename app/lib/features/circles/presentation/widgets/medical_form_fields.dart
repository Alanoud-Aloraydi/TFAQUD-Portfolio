import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:flutter/material.dart';

/// The typed text of the edit form: created from the saved values, and
/// cleared again whenever the state clears it, which happens when «أخرى» is
/// turned off or «لا توجد حساسية» is chosen.
class MedicalFormFields {
  MedicalFormFields(MedicalFileEditState state)
    : firstName = TextEditingController(text: state.firstName),
      lastName = TextEditingController(text: state.lastName),
      conditionOther = TextEditingController(text: state.form.conditionOther),
      medicationOther = TextEditingController(text: state.form.medicationOther),
      foodOther = TextEditingController(text: state.form.foodOther);

  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController conditionOther;
  final TextEditingController medicationOther;
  final TextEditingController foodOther;

  void syncWith(MedicalForm form) {
    if (form.conditionOther.isEmpty) conditionOther.clear();
    if (form.medicationOther.isEmpty) medicationOther.clear();
    if (form.foodOther.isEmpty) foodOther.clear();
  }

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    conditionOther.dispose();
    medicationOther.dispose();
    foodOther.dispose();
  }
}
