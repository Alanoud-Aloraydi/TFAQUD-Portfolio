import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_loading.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reads the readings of a circle's days, and reads them again.
mixin MeasurementReadingsLoading
    on Cubit<MeasurementReadingsState>, MeasurementReadingsScope {
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

  @override
  Future<void> reload() async {
    if (readCircleId != null && readFrom != null && readTo != null) {
      await load(readCircleId!, readFrom!, readTo!, silent: true);
    }
  }
}

/// The readings on screen, with the days they cover.
class MeasurementReadingsState extends Equatable {
  const MeasurementReadingsState({
    this.status = MeasurementLoadStatus.initial,
    this.readings = const [],
    this.errorKey,
  });

  final MeasurementLoadStatus status;
  final List<MeasurementReading> readings;
  final String? errorKey;

  @override
  List<Object?> get props => [status, readings, errorKey];
}
