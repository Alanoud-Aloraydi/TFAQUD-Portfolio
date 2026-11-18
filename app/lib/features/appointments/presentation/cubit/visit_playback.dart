import 'dart:typed_data';

import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/appointments/presentation/cubit/visit_scope.dart';

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
