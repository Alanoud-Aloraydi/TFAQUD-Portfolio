import 'dart:typed_data';

import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';

/// Playing the visit's voice note and stopping it.
mixin VisitPlayback on VisitScope {
  /// True while the recording is being fetched for playback.
  bool _preparing = false;

  /// Downloads the voice note and plays it to the end.
  Future<void> playAudio() async {
    if (_preparing || state.playing || state.paper?.hasAudio != true) return;
    _preparing = true;
    try {
      final Uint8List bytes;
      try {
        bytes = await visits.audio(circleId, appointmentId);
      } catch (error) {
        if (!isClosed) {
          emit(
            state.copyWith(
              errorKey: FailureExceptions.getException(error).messageKey,
            ),
          );
        }
        return;
      }
      final duration = await audio.prepare(bytes);
      if (isClosed) return;
      emit(
        state.copyWith(
          playing: true,
          audioSeconds: duration?.inSeconds,
          clearError: true,
        ),
      );
      await audio.play();
      if (!isClosed) emit(state.copyWith(playing: false));
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(playing: false, errorKey: 'appointments.audio_failed'),
        );
      }
    } finally {
      _preparing = false;
    }
  }

  /// Stops the voice note.
  Future<void> stopAudio() async {
    await audio.stopPlayback();
    if (!isClosed) emit(state.copyWith(playing: false));
  }
}

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
