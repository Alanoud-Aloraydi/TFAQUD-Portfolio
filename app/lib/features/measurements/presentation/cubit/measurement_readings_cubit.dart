import 'dart:async';

import 'package:app/features/measurements/domain/use_cases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_reading_follow_up.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_reading_recording.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_loading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_scope.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_state.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';

/// The readings of one circle over a range of the patient's days, and
/// saving one.
///
/// The «اليوم» tab holds one for today; the record page holds one per
/// month shown. Each reads again whenever the use case says a reading of
/// its circle was saved, wherever it was saved.
class MeasurementReadingsCubit extends Cubit<MeasurementReadingsState>
    with
        MeasurementReadingsScope,
        MeasurementReadingsLoading,
        MeasurementReadingRecording,
        MeasurementReadingFollowUp {
  /// [photoChanges] reloads the readings when a photo or avatar changes
  /// anywhere (who recorded a reading shows theirs).
  MeasurementReadingsCubit(this.measurements, [Listenable? photoChanges])
    : _photoChanges = photoChanges,
      super(const MeasurementReadingsState()) {
    _photoChanges?.addListener(_onPhotoChanged);
    _recorded = measurements.recorded.listen((circleId) {
      if (circleId == readCircleId) unawaited(reload());
    });
  }

  @override
  final MeasurementsUseCase measurements;

  final Listenable? _photoChanges;
  late final StreamSubscription<String> _recorded;

  void _onPhotoChanged() => unawaited(reload());

  @override
  Future<void> close() async {
    _photoChanges?.removeListener(_onPhotoChanged);
    await _recorded.cancel();
    return super.close();
  }
}
