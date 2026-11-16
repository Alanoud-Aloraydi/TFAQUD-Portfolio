import 'package:app/features/circles/presentation/cubit/contact_choice.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_scope.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the person types or picks in the contact form. Every change clears
/// the error the server last gave, so the message belongs to what is on
/// screen now.
mixin ContactFormFields on Cubit<MedicalFileState>, MedicalFileScope {
  /// Fills the open form with a member's name and number.
  void memberChosen(ContactChoice choice) => editForm(
    (ContactForm form) =>
        form.copyWith(name: choice.name, phone: choice.phone, clearError: true),
  );

  void relationChosen(String code) => editForm(
    (ContactForm form) => form.copyWith(relation: code, clearError: true),
  );

  void nameChanged(String value) => editForm(
    (ContactForm form) => form.copyWith(name: value, clearError: true),
  );

  /// [digits] are the digits the user typed, already written 0-9.
  void phoneChanged(String digits) => editForm(
    (ContactForm form) => form.copyWith(phone: digits, clearError: true),
  );

  void editForm(ContactForm Function(ContactForm form) change) {
    final ContactForm? form = state.form;
    if (form == null || form.saving) return;
    emit(state.copyWith(form: change(form)));
  }
}
