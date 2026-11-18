import 'package:app/features/appointments/domain/services/visit_audio.dart';
import 'package:app/features/appointments/domain/use_cases/visits_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/visit_audio_removal.dart';
import 'package:app/features/appointments/presentation/cubit/visit_paper_actions.dart';
import 'package:app/features/appointments/presentation/cubit/visit_playback.dart';
import 'package:app/features/appointments/presentation/cubit/visit_recording.dart';
import 'package:app/features/appointments/presentation/cubit/visit_recording_save.dart';
import 'package:app/features/appointments/presentation/cubit/visit_scope.dart';
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
