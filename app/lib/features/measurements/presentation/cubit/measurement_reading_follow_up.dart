import 'dart:async';

import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_scope.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
