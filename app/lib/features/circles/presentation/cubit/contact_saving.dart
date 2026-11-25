import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/circles/domain/entities/circle_failures.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_options.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/contact_form_opening.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_cubit.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_loading.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Saving the open contact form: a new contact is added, an old one is
/// changed, and the file every other page shows is told.
mixin ContactSaving
    on
        Cubit<MedicalFileState>,
        MedicalFileScope,
        MedicalFileLoading,
        ContactKept {
  /// Returns true when the server saved it.
  Future<bool> saveContact() async {
    final ContactForm? form = state.form;
    final MedicalFile? file = state.file;
    if (form == null || file == null || form.saving) return false;
    final String name = form.name.trim();
    if (!form.relationAnswered || name.isEmpty || !form.phoneValid) {
      emit(state.copyWith(form: form.copyWith(showErrors: true)));
      return false;
    }
    emit(
      state.copyWith(
        form: form.copyWith(saving: true, showErrors: false, clearError: true),
      ),
    );
    final ContactDraft draft = contactDraftOf(form, name);
    final result = form.isNew
        ? await circles.addContact(circleId, draft)
        : await circles.updateContact(circleId, form.contactId!, draft);
    if (isClosed) return false;
    return result.when(
      (EmergencyContact saved) {
        keepContact(saved, isNew: form.isNew, file: file);
        return true;
      },
      (Failure failure) {
        emit(
          state.copyWith(
            form: (state.form ?? form).copyWith(
              saving: false,
              errorKey: failure.messageKey,
            ),
            sessionEnded: endedSession(failure),
          ),
        );
        // The list on screen is out of date: the contact is gone, or another
        // manager added the fifth one.
        if (failure is NotFoundFailure || failure is TooManyContactsFailure) {
          unawaited(load());
        }
        return false;
      },
    );
  }
}

/// The contact as the server takes it, from a form whose relation is
/// answered: the number typed in its national form goes out in its
/// international one, and the words of «أخرى» only with «أخرى».
ContactDraft contactDraftOf(ContactForm form, String name) => ContactDraft(
  name: name,
  relation: form.relation!,
  relationOther: form.relation == MedicalOptions.other
      ? form.relationOther.trim()
      : null,
  phoneNumber: SaudiMobile.international(form.phone),
);
