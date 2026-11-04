import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates measurement readings actions and UI state.
class MeasurementReadingsCubit extends Cubit<MeasurementReadingsState> {
  MeasurementReadingsCubit(this._repository)
    : super(const MeasurementReadingsState());

  final MeasurementRepository _repository;
  String? _circleId;
  String? get circleId => _circleId;
  DateTime? _from;
  DateTime? _to;
  int _revision = 0;

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
      await _repository.record(circleId, draft, occurrence: occurrence);
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
}
