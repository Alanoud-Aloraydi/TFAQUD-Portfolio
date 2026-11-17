import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/domain/medical_form.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_scope.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_edit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Filling the page: from the file already on screen, or from the server.
mixin MedicalFileEditLoading
    on Cubit<MedicalFileEditState>, MedicalFileEditScope {
  /// Fills the page with [file], the file the medical file page already
  /// shows, so the page opens at once without reading it again.
  void start(MedicalFile file) => emit(
    MedicalFileEditState(
      status: MedicalFileEditStatus.ready,
      file: file,
      firstName: file.patient.firstName,
      lastName: file.patient.lastName,
      birthDate: file.patient.birthDate,
      city: file.patient.city,
      timeZone: file.patient.timeZone,
      form: MedicalForm.fromProfile(file.profile),
    ),
  );

  /// Reads the file and fills the page with it (when the page is opened
  /// from its address, without the file).
  Future<void> load() async {
    emit(const MedicalFileEditState());
    final result = await circles.getMedicalFile(circleId);
    if (isClosed) return;
    result.when(
      start,
      (Failure failure) => emit(
        MedicalFileEditState(
          status: MedicalFileEditStatus.failure,
          messageKey: failure.messageKey,
          sessionEnded: endedSession(failure),
        ),
      ),
    );
  }
}
