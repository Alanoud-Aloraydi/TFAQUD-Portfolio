import 'dart:async';

import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/utils/overdue_window.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/domain/usecases/measurements_use_case.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_loading.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';

/// The measurement tasks of one circle, from the patient's day to a month
/// ahead, and «تخطي» on one.
///
/// Reads again whenever the use case says the circle's plans changed or
/// one of its tasks was answered (here, in a reading sheet, or elsewhere
/// as the server said), so no screen has to reload it by hand.
class MeasurementTasksCubit extends Cubit<MeasurementTasksState> {
  /// [photoChanges] reloads the tasks when a photo or avatar changes
  /// anywhere (who recorded a measurement shows theirs).
  MeasurementTasksCubit(this.measurements, [Listenable? photoChanges])
    : _photoChanges = photoChanges,
      super(const MeasurementTasksState()) {
    _photoChanges?.addListener(_onPhotoChanged);
    _subscriptions = [
      measurements.changes.listen(_onCircleChanged),
      measurements.recorded.listen(_onCircleChanged),
    ];
  }

  final MeasurementsUseCase measurements;
  final Listenable? _photoChanges;
  late final List<StreamSubscription<String>> _subscriptions;

  void _onPhotoChanged() => unawaited(reload());

  void _onCircleChanged(String circleId) {
    if (circleId == readCircleId) unawaited(reload());
  }

  @override
  Future<void> close() async {
    _photoChanges?.removeListener(_onPhotoChanged);
    for (final StreamSubscription<String> item in _subscriptions) {
      await item.cancel();
    }
    return super.close();
  }

  /// Reads [circleId]'s tasks from the first overdue day before the
  /// patient's [day] to 30 calendar days later, so «يحتاج انتباهك» keeps an
  /// unrecorded task until its last overdue day.
  /// With [silent] a list already shown stays while it is read again (no
  /// loading state), and a failure keeps it.
  Future<void> load(String circleId, DateTime day, {bool silent = false}) =>
      loadRange(
        circleId,
        overdueStart(day),
        DateTime(day.year, day.month, day.day + 30),
        silent: silent,
      );

  /// The circle and the patient's days read last.
  String? readCircleId;
  DateTime? readFrom;
  DateTime? readTo;

  /// Goes up at each load, so an older reading that ends later is dropped.
  int revision = 0;

  /// The tasks being skipped: a second tap on one skips nothing.
  final Set<MeasurementOccurrence> skipping = {};

  /// Reads an exact patient-calendar range for read-only history views.
  Future<void> loadRange(
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
        MeasurementTasksState(
          status: MeasurementLoadStatus.loading,
          tasks: changedQuery ? const [] : state.tasks,
        ),
      );
    }
    try {
      final tasks = await measurements.occurrences(circleId, from, to);
      if (isClosed || revision != this.revision) return;
      emit(
        MeasurementTasksState(
          status: MeasurementLoadStatus.ready,
          tasks: tasks,
        ),
      );
    } catch (error) {
      if (isClosed || revision != this.revision) return;
      emit(
        MeasurementTasksState(
          status: keep
              ? MeasurementLoadStatus.ready
              : MeasurementLoadStatus.failure,
          tasks: state.tasks,
          errorKey: keep
              ? null
              : FailureExceptions.getException(error).messageKey,
        ),
      );
    }
  }

  /// Reads the last load again, quietly: what is shown stays meanwhile.
  Future<void> reload() async {
    if (readCircleId != null && readFrom != null && readTo != null) {
      await loadRange(readCircleId!, readFrom!, readTo!, silent: true);
    }
  }

  /// «تخطي» on [occurrence], the task the person chose. Null when skipped
  /// (the list reads again through the use case), else the message key
  /// to show; a second tap while it saves is ignored (null).
  Future<String?> skip(
    MeasurementOccurrence occurrence,
    MeasurementReadingDraft draft,
  ) async {
    final circleId = readCircleId;
    if (circleId == null || !skipping.add(occurrence)) return null;
    try {
      await measurements.record(circleId, draft, occurrence: occurrence);
      return null;
    } catch (error) {
      return FailureExceptions.getException(error).messageKey;
    } finally {
      skipping.remove(occurrence);
    }
  }
}
