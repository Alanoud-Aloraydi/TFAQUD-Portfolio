import 'dart:async';

import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/domain/entities/visit_paper.dart';
import 'package:app/features/appointments/presentation/cubit/visit_cubit.dart';
import 'package:app/features/appointments/presentation/cubit/visit_playback.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';

/// Reading and saving the written visit paper.
mixin VisitPaperActions on VisitScope {
  /// Reads the visit paper; [VisitState.loadFailed] says when it could not.
  Future<void> load() async {
    emit(state.copyWith(loading: true, loadFailed: false, clearError: true));
    try {
      final paper = await visits.get(circleId, appointmentId);
      if (!isClosed) {
        emit(state.copyWith(loading: false, paper: paper, replacePaper: true));
      }
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            loading: false,
            loadFailed: true,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
    }
  }

  /// Saves the written paper; false when the server said no.
  Future<bool> save(VisitPaperDraft draft) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, clearError: true));
    try {
      final paper = await visits.save(circleId, appointmentId, draft);
      if (!isClosed) {
        emit(state.copyWith(saving: false, paper: paper, replacePaper: true));
      }
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          state.copyWith(
            saving: false,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
      return false;
    }
  }
}

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
