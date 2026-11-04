import 'dart:async';

import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/data/visit_audio_service.dart';
import 'package:app/features/appointments/data/visit_repository.dart';
import 'package:app/features/appointments/domain/visit_paper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the visit presentation state.
class VisitState extends Equatable {
  const VisitState({
    this.loading = true,
    this.saving = false,
    this.recording = false,
    this.playing = false,
    this.recordedSeconds = 0,
    this.audioSeconds,
    this.paper,
    this.errorKey,
  });

  final bool loading;
  final bool saving;
  final bool recording;
  final bool playing;
  final int recordedSeconds;
  final int? audioSeconds;
  final VisitPaper? paper;
  final String? errorKey;

  VisitState copyWith({
    bool? loading,
    bool? saving,
    bool? recording,
    bool? playing,
    int? recordedSeconds,
    int? audioSeconds,
    VisitPaper? paper,
    bool replacePaper = false,
    String? errorKey,
    bool clearError = false,
  }) => VisitState(
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    recording: recording ?? this.recording,
    playing: playing ?? this.playing,
    recordedSeconds: recordedSeconds ?? this.recordedSeconds,
    audioSeconds: audioSeconds ?? this.audioSeconds,
    paper: replacePaper ? paper : this.paper,
    errorKey: clearError ? null : errorKey ?? this.errorKey,
  );

  @override
  List<Object?> get props => [
    loading,
    saving,
    recording,
    playing,
    recordedSeconds,
    audioSeconds,
    paper,
    errorKey,
  ];
}

/// Coordinates visit actions and UI state.
class VisitCubit extends Cubit<VisitState> {
  VisitCubit(this._repository, this._audio, this.circleId, this.appointmentId)
    : super(const VisitState());

  final VisitRepository _repository;
  final VisitAudioService _audio;
  final String circleId;
  final String appointmentId;
  Timer? _recordingTimer;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
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
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
    }
  }

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

  Future<void> startRecording() async {
    if (state.recording || state.saving) return;
    try {
      if (!await _audio.start()) {
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
        if (seconds >= 300) unawaited(stopAndSaveRecording());
      });
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(errorKey: 'appointments.audio_failed'));
      }
    }
  }

  Future<void> stopAndSaveRecording() async {
    if (!state.recording) return;
    _recordingTimer?.cancel();
    emit(state.copyWith(recording: false, saving: true, clearError: true));
    try {
      final bytes = await _audio.stop();
      if (bytes == null) throw StateError('Recording had no file');
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
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(saving: false, errorKey: 'appointments.audio_failed'),
        );
      }
    }
  }

  Future<void> cancelRecording() async {
    if (!state.recording) return;
    _recordingTimer?.cancel();
    await _audio.cancel();
    if (!isClosed) emit(state.copyWith(recording: false));
  }

  Future<void> playAudio() async {
    if (state.playing || state.paper?.hasAudio != true) return;
    try {
      final bytes = await _repository.audio(circleId, appointmentId);
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
    }
  }

  Future<void> stopAudio() async {
    await _audio.stopPlayback();
    if (!isClosed) emit(state.copyWith(playing: false));
  }

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
