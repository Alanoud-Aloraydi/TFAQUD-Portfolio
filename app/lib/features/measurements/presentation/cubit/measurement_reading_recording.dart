import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_load_status.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_scope.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Saves a reading, and shows it at once when its day is on screen.
mixin MeasurementReadingRecording
    on Cubit<MeasurementReadingsState>, MeasurementReadingsScope {
  /// Saves [draft], the answer to [occurrence] (the task the person chose)
  /// or a free reading without it. Null when saved, else the message key
  /// to show; a second tap while it saves is ignored (null).
  ///
  /// A time read still to come on the patient's [clock] is refused here,
  /// as the server would. The reading shows at once when its day is in the
  /// days read; the list then reads again through the use case.
  Future<String?> record(
    MeasurementReadingDraft draft, {
    required PatientClock clock,
    MeasurementOccurrence? occurrence,
  }) async {
    final circleId = readCircleId;
    if (circleId == null || writing) return null;
    final DateTime? measuredAt = draft.measuredAt;
    if (measuredAt != null && clock.wallTime(measuredAt).isAfter(clock.now())) {
      return 'measurements.future_reading';
    }
    writing = true;
    try {
      final reading = await measurements.record(
        circleId,
        draft,
        occurrence: occurrence,
      );
      if (isClosed) return null;
      final day = reading.measuredAt == null
          ? reading.scheduledOn
          : clock.today(reading.measuredAt);
      final from = readFrom;
      final to = readTo;
      if (day != null &&
          from != null &&
          to != null &&
          !day.isBefore(from) &&
          !day.isAfter(to)) {
        emit(
          MeasurementReadingsState(
            status: MeasurementLoadStatus.ready,
            readings: [reading, ...state.readings],
          ),
        );
      }
      return null;
    } catch (error) {
      return FailureExceptions.getException(error).messageKey;
    } finally {
      writing = false;
    }
  }
}
