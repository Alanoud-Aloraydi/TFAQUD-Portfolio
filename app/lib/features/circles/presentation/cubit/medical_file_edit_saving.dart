import 'package:app/core/errors/auth_failures.dart';
import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/usecases/circles_use_case.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_changes.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Saving the edit page.
mixin MedicalFileEditSaving
    on Cubit<MedicalFileEditState>, MedicalFileEditScope {
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

/// What the edit page of the medical file is bound to.
mixin MedicalFileEditScope on Cubit<MedicalFileEditState> {
  CirclesUseCase get circles;

  /// The circle whose file is edited.
  String get circleId;

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
}
