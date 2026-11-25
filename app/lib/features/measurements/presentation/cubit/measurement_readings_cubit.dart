import 'dart:async';

import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_reading_recording.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_loading.dart';
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

/// «تمت المتابعة» on a reading outside its target.
mixin MeasurementReadingFollowUp
    on Cubit<MeasurementReadingsState>, MeasurementReadingsScope {
  /// «تمت المتابعة» on [reading], a reading outside its target. Null when
  /// saved, else the message key to show.
  Future<String?> followUp(MeasurementReading reading) async {
    final circleId = readCircleId;
    if (circleId == null || writing) return null;
    writing = true;
    try {
      await measurements.followUp(circleId, reading.id);
      if (!isClosed) unawaited(reload());
      return null;
    } catch (error) {
      return FailureExceptions.getException(error).messageKey;
    } finally {
      writing = false;
    }
  }
}

/// What the readings of one circle are bound to, shared by reading them
/// and by saving one.
mixin MeasurementReadingsScope on Cubit<MeasurementReadingsState> {
  MeasurementsUseCase get measurements;

  /// The circle and the patient's days read last.
  String? readCircleId;
  DateTime? readFrom;
  DateTime? readTo;

  /// The circle read last; null before the first load.
  String? get circleId => readCircleId;

  /// Goes up at each load, so an older reading that ends later is dropped.
  int revision = 0;

  /// True while a reading or a follow-up is saving: a second tap saves
  /// nothing.
  bool writing = false;

  /// Reads the last load again, quietly: what is shown stays meanwhile.
  Future<void> reload();
}
