import 'dart:async';

import 'package:app/features/appointments/presentation/cubit/visit_recording_save.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';

/// Starting a recording, counting it, and dropping it unsaved.
mixin VisitRecording on VisitRecordingSave {
  /// True from the tap on «تسجيل» until the permission prompt is answered.
  bool _starting = false;

  /// Starts recording once the microphone is allowed; otherwise says why not.
  Future<void> startRecording() async {
    if (_starting || state.recording || state.saving) return;
    _starting = true;
    try {
      final started = await audio.start();
      // The screen can leave while the permission prompt is open; `close`
      // has already disposed the recorder then.
      if (isClosed) return;
      if (!started) {
        emit(state.copyWith(errorKey: 'appointments.microphone_denied'));
        return;
      }
      emit(
        state.copyWith(recording: true, recordedSeconds: 0, clearError: true),
      );
      recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (isClosed) return;
        final seconds = state.recordedSeconds + 1;
        emit(state.copyWith(recordedSeconds: seconds));
        if (seconds >= maxRecordingSeconds) unawaited(stopAndSaveRecording());
      });
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(errorKey: 'appointments.audio_failed'));
      }
    } finally {
      _starting = false;
    }
  }

  /// Drops the recording without saving it.
  Future<void> cancelRecording() async {
    if (!state.recording) return;
    recordingTimer?.cancel();
    await audio.cancel();
    if (!isClosed) emit(state.copyWith(recording: false));
  }
}
