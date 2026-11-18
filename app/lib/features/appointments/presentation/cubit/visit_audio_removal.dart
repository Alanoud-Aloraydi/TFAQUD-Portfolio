import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/presentation/cubit/visit_scope.dart';

/// Deleting the visit's voice note.
mixin VisitAudioRemoval on VisitScope {
  /// Deletes the voice note and keeps the written paper.
  Future<void> removeAudio() async {
    if (state.saving) return;
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await audio.stopPlayback();
      final paper = await visits.removeAudio(circleId, appointmentId);
      if (!isClosed) {
        emit(
          state.copyWith(
            saving: false,
            playing: false,
            paper: paper,
            replacePaper: true,
          ),
        );
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            saving: false,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
    }
  }
}
