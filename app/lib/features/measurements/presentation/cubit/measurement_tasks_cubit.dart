import 'dart:async';

import 'package:app/core/errors/network_exceptions.dart';
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
  DateTime? _day;

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

  /// Reads [circleId]'s tasks from the patient's [day] to 30 calendar days
  /// later; the list of another circle or day is cleared first.
  /// With [silent] a list already shown stays while it is read again (no
  /// loading state), and a failure keeps it.
  Future<void> load(
    String circleId,
    DateTime day, {
    bool silent = false,
  }) async {
    final changedQuery = _circleId != circleId || _day != day;
    _circleId = circleId;
    _day = day;
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
      final tasks = await _repository.occurrences(
        circleId,
        day,
        // Calendar days, not 30 × 24 hours: a phone's own DST would make
        // it one day short.
        DateTime(day.year, day.month, day.day + 30),
      );
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
    if (_circleId != null && _day != null) {
      await load(_circleId!, _day!, silent: true);
    }
  }

  /// «تخطي» on [occurrence], the task the person chose. Null when skipped
  /// (the list reads again through the repository), else the message key
  /// to show; a second tap while it saves is ignored (null).
  Future<String?> skip(MeasurementOccurrence occurrence) async {
    final circleId = _circleId;
    if (circleId == null || !_skipping.add(occurrence)) return null;
    try {
      await _repository.record(
        circleId,
        MeasurementReadingDraft(kind: occurrence.kind, outcome: 'skipped'),
        occurrence: occurrence,
      );
      return null;
    } catch (error) {
      return FailureExceptions.getException(error).messageKey;
    } finally {
      _skipping.remove(occurrence);
    }
  }
}
