import 'dart:async';

import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_loading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_loading.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';

/// The readings of one circle over a range of the patient's days, and
/// saving one.
///
/// The «اليوم» tab holds one for today; the record page holds one per
/// month shown. Each reads again whenever the use case says a reading of
/// its circle was saved, wherever it was saved.
class MeasurementReadingsCubit extends Cubit<MeasurementReadingsState> {
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

  /// Reads [circleId]'s readings of the patient's days [from] to [to], both
  /// included; the list of another circle or range is cleared first.
  /// With [silent] a list already shown stays while it is read again (no
  /// loading state), and a failure keeps it.
  Future<void> load(
    String circleId,
    DateTime from,
    DateTime to, {
    bool silent = false,
  }) async {
    final changedQuery =
        readCircleId != circleId || readFrom != from || readTo != to;
    readCircleId = circleId;
    readFrom = from;
    readTo = to;
    final revision = ++this.revision;
    final bool keep =
        silent && !changedQuery && state.status == MeasurementLoadStatus.ready;
    if (!keep) {
      emit(
        MeasurementReadingsState(
          status: MeasurementLoadStatus.loading,
          readings: changedQuery ? const [] : state.readings,
        ),
      );
    }
    try {
      final readings = await measurements.readings(circleId, from, to);
      if (isClosed || revision != this.revision) return;
      emit(
        MeasurementReadingsState(
          status: MeasurementLoadStatus.ready,
          readings: readings,
        ),
      );
    } catch (error) {
      if (isClosed || revision != this.revision) return;
      emit(
        MeasurementReadingsState(
          status: keep
              ? MeasurementLoadStatus.ready
              : MeasurementLoadStatus.failure,
          readings: state.readings,
          errorKey: keep
              ? null
              : FailureExceptions.getException(error).messageKey,
        ),
      );
    }
  }

  Future<void> reload() async {
    if (readCircleId != null && readFrom != null && readTo != null) {
      await load(readCircleId!, readFrom!, readTo!, silent: true);
    }
  }

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
