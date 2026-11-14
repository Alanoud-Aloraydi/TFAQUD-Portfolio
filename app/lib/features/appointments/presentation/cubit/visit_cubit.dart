import 'dart:async';
import 'dart:typed_data';

import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/domain/services/visit_audio.dart';
import 'package:app/features/appointments/domain/use_cases/visits_use_case.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates visit actions and UI state.
class VisitCubit extends Cubit<VisitState> {
  VisitCubit(this._repository, this._audio, this.circleId, this.appointmentId)
    : super(const VisitState());

  final VisitsUseCase _repository;
  final VisitAudio _audio;
  final String circleId;
  final String appointmentId;
  Timer? _recordingTimer;

  /// True from the tap on «تسجيل» until the permission prompt is answered.
  bool _starting = false;

  /// True while the recording is being fetched for playback.
  bool _preparing = false;

  /// Reads the visit paper; [VisitState.loadFailed] says when it could not.
  Future<void> load() async {
    emit(state.copyWith(loading: true, loadFailed: false, clearError: true));
    try {
      final paper = await _repository.get(circleId, appointmentId);
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
      final paper = await _repository.save(circleId, appointmentId, draft);
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

  /// Starts recording once the microphone is allowed; otherwise says why not.
  Future<void> startRecording() async {
    if (_starting || state.recording || state.saving) return;
    _starting = true;
    try {
      final started = await _audio.start();
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
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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

  /// Ends the recording and uploads it, replacing the visit's voice note.
  Future<void> stopAndSaveRecording() async {
    if (!state.recording) return;
    _recordingTimer?.cancel();
    emit(state.copyWith(recording: false, saving: true, clearError: true));
    final Uint8List? bytes;
    try {
      bytes = await _audio.stop();
    } catch (_) {
      _failSaving('appointments.audio_failed');
      return;
    }
    if (bytes == null) {
      _failSaving('appointments.audio_failed');
      return;
    }
    try {
      final paper = await _repository.saveAudio(circleId, appointmentId, bytes);
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

  /// Drops the recording without saving it.
  Future<void> cancelRecording() async {
    if (!state.recording) return;
    _recordingTimer?.cancel();
    await _audio.cancel();
    if (!isClosed) emit(state.copyWith(recording: false));
  }

  /// Downloads the voice note and plays it to the end.
  Future<void> playAudio() async {
    if (_preparing || state.playing || state.paper?.hasAudio != true) return;
    _preparing = true;
    try {
      final Uint8List bytes;
      try {
        bytes = await _repository.audio(circleId, appointmentId);
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
      final duration = await _audio.prepare(bytes);
      if (isClosed) return;
      emit(
        state.copyWith(
          playing: true,
          audioSeconds: duration?.inSeconds,
          clearError: true,
        ),
      );
      await _audio.play();
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
    await _audio.stopPlayback();
    if (!isClosed) emit(state.copyWith(playing: false));
  }

  /// Deletes the voice note and keeps the written paper.
  Future<void> removeAudio() async {
    if (state.saving) return;
    emit(state.copyWith(saving: true, clearError: true));
    try {
      await _audio.stopPlayback();
      final paper = await _repository.removeAudio(circleId, appointmentId);
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

  @override
  Future<void> close() async {
    _recordingTimer?.cancel();
    if (state.recording) await _audio.cancel();
    await _audio.dispose();
    await super.close();
  }
}
