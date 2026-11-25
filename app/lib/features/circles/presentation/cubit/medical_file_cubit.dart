import 'dart:async';

import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/contact_deleting.dart';
import 'package:app/features/circles/presentation/cubit/contact_form.dart';
import 'package:app/features/circles/presentation/cubit/contact_form_opening.dart';
import 'package:app/features/circles/presentation/cubit/contact_saving.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_loading.dart';
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
