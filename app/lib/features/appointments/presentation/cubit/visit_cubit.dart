import 'dart:async';

import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/domain/repositories/visit_audio.dart';
import 'package:app/features/appointments/domain/usecases/visits_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/visit_paper_actions.dart';
import 'package:app/features/appointments/presentation/cubit/visit_playback.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates visit actions and UI state.
class VisitCubit extends Cubit<VisitState>
    with
        VisitScope,
        VisitPaperActions,
        VisitRecordingSave,
        VisitRecording,
        VisitPlayback,
        VisitAudioRemoval {
  VisitCubit(this.visits, this.audio, this.circleId, this.appointmentId)
    : super(const VisitState());

  @override
  final VisitsUseCase visits;
  @override
  final VisitAudio audio;
  @override
  final String circleId;
  @override
  final String appointmentId;

  @override
  Future<void> close() async {
    recordingTimer?.cancel();
    if (state.recording) await audio.cancel();
    await audio.dispose();
    await super.close();
  }
}

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

/// What every part of the visit cubit works on: the visit it is about, the
/// server and the microphone.
mixin VisitScope on Cubit<VisitState> {
  VisitsUseCase get visits;
  VisitAudio get audio;
  String get circleId;
  String get appointmentId;

  /// Counts the seconds of a recording while it runs.
  Timer? recordingTimer;
}
