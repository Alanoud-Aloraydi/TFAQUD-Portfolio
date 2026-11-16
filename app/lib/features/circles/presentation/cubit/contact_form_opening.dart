import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/contact_choices_of.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_scope.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opening the contact form, on a new contact or one already saved, and
/// closing it again.
mixin ContactFormOpening on Cubit<MedicalFileState>, MedicalFileScope {
  /// Opens an empty form, when there is room for one more contact, and
  /// reads the circle's members it can be picked from.
  void startAdd() {
    final MedicalFile? file = state.file;
    if (file == null || !file.canAddContact || state.form != null) return;
    emit(state.copyWith(form: const ContactForm()));
    loadChoices();
  }

  /// The members with a Saudi number, read once. The form works without
  /// them: a failure only leaves the list out.
  Future<void> loadChoices() async {
    if (state.choices != null) return;
    final result = await circles.getCircleOverview(circleId);
    if (isClosed) return;
    final CircleOverview? overview = result.tryGetSuccess();
    if (overview == null) return;
    emit(state.copyWith(choices: contactChoicesOf(overview)));
  }

  /// Opens the form with the saved values of a contact.
  void startEdit(String contactId) {
    final MedicalFile? file = state.file;
    if (file == null || state.form != null) return;
    for (final EmergencyContact contact in file.contacts) {
      if (contact.id == contactId) {
        emit(
          state.copyWith(
            form: ContactForm(
              contactId: contact.id,
              relation: contact.relation,
              name: contact.name,
              phone: contact.nationalNumber,
            ),
          ),
        );
        return;
      }
    }
  }

  void cancelForm() {
    if (state.form?.saving ?? false) return;
    emit(state.copyWith(clearForm: true));
  }
}
