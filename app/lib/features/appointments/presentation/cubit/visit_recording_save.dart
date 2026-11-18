import 'dart:typed_data';

import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/presentation/cubit/visit_scope.dart';

/// Ending a recording and keeping it as the visit's voice note.
mixin VisitRecordingSave on VisitScope {
  /// Ends the recording and uploads it, replacing the visit's voice note.
  Future<void> stopAndSaveRecording() async {
    if (!state.recording) return;
    recordingTimer?.cancel();
    emit(state.copyWith(recording: false, saving: true, clearError: true));
    final Uint8List? bytes;
    try {
      bytes = await audio.stop();
    } catch (_) {
      _failSaving('appointments.audio_failed');
      return;
    }
    if (bytes == null) {
      _failSaving('appointments.audio_failed');
      return;
    }
    try {
      final paper = await visits.saveAudio(circleId, appointmentId, bytes);
      if (!isClosed) {
        emit(
          state.copyWith(
            saving: false,
            paper: paper,
            replacePaper: true,
            audioSeconds: state.recordedSeconds,
          ),
        );
      }
    } catch (error) {
      _failSaving(FailureExceptions.getException(error).messageKey);
    }
  }

  void _failSaving(String errorKey) {
    if (!isClosed) emit(state.copyWith(saving: false, errorKey: errorKey));
  }
}
