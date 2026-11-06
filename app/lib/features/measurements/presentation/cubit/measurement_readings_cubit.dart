import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/core/utils/riyadh_time.dart';

import 'dart:async';

import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates measurement readings actions and UI state.
class MeasurementReadingsCubit extends Cubit<MeasurementReadingsState> {
  MeasurementReadingsCubit(this._repository, [Listenable? photoChanges])
    : _photoChanges = photoChanges,
      super(const MeasurementReadingsState()) {
    // Who recorded a reading shows their avatar; a saved photo or avatar
    // anywhere reloads it too, not just the screen that saved it.
    _photoChanges?.addListener(_onPhotoChanged);
  }

  final MeasurementRepository _repository;
  final Listenable? _photoChanges;
  String? _circleId;
  String? get circleId => _circleId;
  DateTime? _from;
  DateTime? _to;
  int _revision = 0;
  int _recordRevision = 0;
  int get recordRevision => _recordRevision;

  Future<void> load(String circleId, DateTime from, DateTime to) async {
    final changedQuery = _circleId != circleId || _from != from || _to != to;
    _circleId = circleId;
    _from = from;
    _to = to;
    final revision = ++_revision;
    emit(
      MeasurementReadingsState(
        status: MeasurementLoadStatus.loading,
        readings: changedQuery ? const [] : state.readings,
      ),
    );
    try {
      final readings = await _repository.readings(circleId, from, to);
      if (isClosed || revision != _revision) return;
      emit(
        MeasurementReadingsState(
          status: MeasurementLoadStatus.ready,
          readings: readings,
        ),
      );
    } catch (error) {
      if (isClosed || revision != _revision) return;
      emit(
        MeasurementReadingsState(
          status: MeasurementLoadStatus.failure,
          readings: state.readings,
          errorKey: FailureExceptions.getException(error).messageKey,
        ),
      );
    }
  }

  Future<void> reload() async {
    if (_circleId != null && _from != null && _to != null) {
      await load(_circleId!, _from!, _to!);
    }
  }

  Future<bool> record(
    MeasurementReadingDraft draft, {
    MeasurementOccurrence? occurrence,
  }) async {
    final circleId = _circleId;
    if (circleId == null) return false;
    try {
      final reading = await _repository.record(
        circleId,
        draft,
        occurrence: occurrence,
      );
      if (isClosed) return true;
      _recordRevision++;
      final day = reading.measuredAt == null
          ? reading.scheduledOn
          : scheduleDay(riyadhNow(reading.measuredAt!));
      final visible =
          day != null &&
          _from != null &&
          _to != null &&
          !day.isBefore(_from!) &&
          !day.isAfter(_to!);
      emit(
        MeasurementReadingsState(
          status: MeasurementLoadStatus.ready,
          readings: visible ? [reading, ...state.readings] : state.readings,
        ),
      );
      unawaited(reload());
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          MeasurementReadingsState(
            status: MeasurementLoadStatus.ready,
            readings: state.readings,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> followUp(MeasurementReading reading) async {
    final circleId = _circleId;
    if (circleId == null) return false;
    try {
      await _repository.followUp(circleId, reading.id);
      await reload();
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          MeasurementReadingsState(
            status: MeasurementLoadStatus.ready,
            readings: state.readings,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
      return false;
    }
  }

  void _onPhotoChanged() => unawaited(reload());

  @override
  Future<void> close() async {
    _photoChanges?.removeListener(_onPhotoChanged);
    return super.close();
  }
}
