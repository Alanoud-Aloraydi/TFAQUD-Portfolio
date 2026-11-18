import 'dart:async';

import 'package:app/features/appointments/domain/services/visit_audio.dart';
import 'package:app/features/appointments/domain/use_cases/visits_use_case.dart';
import 'package:app/features/appointments/presentation/cubit/visit_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
