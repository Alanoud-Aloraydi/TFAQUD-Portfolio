import 'dart:async';

import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/utils/overdue_window.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';

/// The measurement tasks of one circle, from the patient's day to a month
/// ahead, and «تخطي» on one.
///
/// Reads again whenever the repository says the circle's plans changed or
/// one of its tasks was answered (here, in a reading sheet, or elsewhere
/// as the server said), so no screen has to reload it by hand.
class MeasurementTasksCubit extends Cubit<MeasurementTasksState> {
  /// [photoChanges] reloads the tasks when a photo or avatar changes
  /// anywhere (who recorded a measurement shows theirs).
  MeasurementTasksCubit(this._repository, [Listenable? photoChanges])
    : _photoChanges = photoChanges,
      super(const MeasurementTasksState()) {
    _photoChanges?.addListener(_onPhotoChanged);
    _subscriptions = [
      _repository.changes.listen(_onCircleChanged),
      _repository.recorded.listen(_onCircleChanged),
    ];
  }

  final MeasurementRepository _repository;
  final Listenable? _photoChanges;
  late final List<StreamSubscription<String>> _subscriptions;
  String? _circleId;
  DateTime? _from;
  DateTime? _to;

  /// Goes up at each [load], so an older reading that ends later is dropped.
  int _revision = 0;

  /// The tasks being skipped: a second tap on one skips nothing.
  final Set<MeasurementOccurrence> _skipping = {};

  void _onPhotoChanged() => unawaited(reload());

  void _onCircleChanged(String circleId) {
    if (circleId == _circleId) unawaited(reload());
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

  /// Reads an exact patient-calendar range for read-only history views.
  Future<void> loadRange(
    String circleId,
    DateTime from,
    DateTime to, {
    bool silent = false,
  }) async {
    final changedQuery = _circleId != circleId || _from != from || _to != to;
    _circleId = circleId;
    _from = from;
    _to = to;
    final revision = ++_revision;
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
      final tasks = await _repository.occurrences(circleId, from, to);
      if (isClosed || revision != _revision) return;
      emit(
        MeasurementTasksState(
          status: MeasurementLoadStatus.ready,
          tasks: tasks,
        ),
      );
    } catch (error) {
      if (isClosed || revision != _revision) return;
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

  /// Reads the last [load] again, quietly: what is shown stays meanwhile.
  Future<void> reload() async {
    if (_circleId != null && _from != null && _to != null) {
      await loadRange(_circleId!, _from!, _to!, silent: true);
    }
  }

  /// «تخطي» on [occurrence], the task the person chose. Null when skipped
  /// (the list reads again through the repository), else the message key
  /// to show; a second tap while it saves is ignored (null).
  Future<String?> skip(
    MeasurementOccurrence occurrence,
    MeasurementReadingDraft draft,
  ) async {
    final circleId = _circleId;
    if (circleId == null || !_skipping.add(occurrence)) return null;
    try {
      await _repository.record(circleId, draft, occurrence: occurrence);
      return null;
    } catch (error) {
      return FailureExceptions.getException(error).messageKey;
    } finally {
      _skipping.remove(occurrence);
    }
  }
}
