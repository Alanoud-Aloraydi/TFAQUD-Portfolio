import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_failures.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_scope.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Removing the contact of the open form.
mixin ContactDeleting on Cubit<MedicalFileState>, MedicalFileScope {
  /// Returns true when it is gone.
  Future<bool> deleteContact() async {
    final ContactForm? form = state.form;
    final MedicalFile? file = state.file;
    final String? contactId = form?.contactId;
    if (form == null || file == null || contactId == null || form.saving) {
      return false;
    }
    emit(state.copyWith(form: form.copyWith(saving: true, clearError: true)));
    final result = await circles.deleteContact(circleId, contactId);
    if (isClosed) return false;
    return result.when(
      (_) {
        _removed(contactId);
        return true;
      },
      (Failure failure) {
        if (failure is NotFoundFailure) {
          // Another manager removed it first: it is gone either way.
          _removed(contactId);
          return true;
        }
        emit(
          state.copyWith(
            form: (state.form ?? form).copyWith(
              saving: false,
              errorKey: failure.messageKey,
            ),
            sessionEnded: endedSession(failure),
          ),
        );
        return false;
      },
    );
  }

  /// Takes the contact off the page and tells the other pages.
  void _removed(String contactId) {
    final MedicalFile current = state.file!;
    final MedicalFile updated = current.copyWith(
      contacts: <EmergencyContact>[
        for (final EmergencyContact contact in current.contacts)
          if (contact.id != contactId) contact,
      ],
    );
    emit(state.copyWith(file: updated, clearForm: true));
    circles.medicalFileSaved(circleId, updated);
  }
}
