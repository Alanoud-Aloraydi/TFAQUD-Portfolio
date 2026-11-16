import 'package:app/core/errors/failure.dart';
import 'package:app/features/circles/domain/entities/medical_file.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_scope.dart';
import 'package:app/features/circles/presentation/cubit/medical_file_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
