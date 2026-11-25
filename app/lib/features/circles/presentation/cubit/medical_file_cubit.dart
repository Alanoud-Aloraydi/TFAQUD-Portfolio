import 'dart:async';

import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/features/circles/domain/entities/circle_failures.dart';
import 'package:app/features/circles/domain/entities/emergency_contact.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/entities/medical_options.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/contact_deleting.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/contact_form_opening.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The medical file page (CIRCLE-05): reads the file of one circle and adds,
/// changes and removes its emergency contacts. The health answers, the birth
/// date and the city are changed on the edit page.
class MedicalFileCubit extends Cubit<MedicalFileState>
    with
        MedicalFileScope,
        MedicalFileLoading,
        ContactFormOpening,
        ContactFormFields,
        ContactKept,
        ContactSaving,
        ContactDeleting {
  MedicalFileCubit(this.circles, this.circleId)
    : super(const MedicalFileState()) {
    _saves = circles.medicalFileSaves(circleId).listen(takeSaved);
  }

  @override
  final CirclesUseCase circles;

  @override
  final String circleId;

  /// The files saved on the edit page while this page is open under it.
  late final StreamSubscription<MedicalFile> _saves;

  @override
  Future<void> close() async {
    await _saves.cancel();
    return super.close();
  }
}

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

  /// The words typed for «أخرى».
  void relationOtherChanged(String value) => editForm(
    (ContactForm form) => form.copyWith(relationOther: value, clearError: true),
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

/// What the medical file page is bound to, shared by everything it does.
mixin MedicalFileScope on Cubit<MedicalFileState> {
  /// The use case the cubit was made with.
  CirclesUseCase get circles;

  /// The circle whose file is shown.
  String get circleId;

  /// Counts the readings, so a reading that started before a save is
  /// dropped when it arrives.
  int revision = 0;

  /// Whether the session itself ended, which the page answers by leaving.
  bool endedSession(Failure failure) =>
      failure is UnauthorizedFailure || failure is SessionExpiredFailure;
}

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

/// Reading the file, and taking in one saved on another page.
mixin MedicalFileLoading on Cubit<MedicalFileState>, MedicalFileScope {
  /// Shows a file saved on another page (the edit page) at once, without
  /// reading it again. A read that started before the save is older, so it
  /// is dropped when it arrives.
  void takeSaved(MedicalFile file) {
    if (isClosed || state.status != MedicalFileStatus.ready) return;
    revision++;
    emit(state.copyWith(file: file));
  }

  /// Reads the file. The first read shows the loading state; a later read
  /// (when the person comes back from the edit page) keeps the page on
  /// screen until the new file arrives, and a failure of a later read keeps
  /// the old file.
  Future<void> load() async {
    final int revision = ++this.revision;
    if (state.status != MedicalFileStatus.ready) {
      emit(const MedicalFileState());
    }
    final result = await circles.getMedicalFile(circleId);
    if (isClosed || revision != this.revision) return;
    result.when(
      (MedicalFile file) =>
          emit(state.copyWith(status: MedicalFileStatus.ready, file: file)),
      (Failure failure) {
        if (state.status == MedicalFileStatus.ready) {
          if (endedSession(failure)) {
            emit(state.copyWith(sessionEnded: true));
          }
          return;
        }
        emit(
          MedicalFileState(
            status: MedicalFileStatus.failure,
            messageKey: failure.messageKey,
            sessionEnded: endedSession(failure),
          ),
        );
      },
    );
  }
}
