import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MeasurementTasksCubit extends Cubit<MeasurementTasksState> {
  MeasurementTasksCubit(this._repository)
    : super(const MeasurementTasksState());

  final MeasurementRepository _repository;
  String? _circleId;
  DateTime? _day;
  int _revision = 0;

  Future<void> load(String circleId, DateTime day) async {
    final changedQuery = _circleId != circleId || _day != day;
    _circleId = circleId;
    _day = day;
    final revision = ++_revision;
    emit(
      MeasurementTasksState(
        status: MeasurementLoadStatus.loading,
        tasks: changedQuery ? const [] : state.tasks,
      ),
    );
    try {
      final tasks = await _repository.occurrences(circleId, day, day);
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
          status: MeasurementLoadStatus.failure,
          tasks: state.tasks,
          errorKey: FailureExceptions.getException(error).messageKey,
        ),
      );
    }
  }

  Future<void> reload() async {
    if (_circleId != null && _day != null) await load(_circleId!, _day!);
  }

  Future<bool> skip(MeasurementOccurrence occurrence) async {
    final circleId = _circleId;
    if (circleId == null) return false;
    try {
      await _repository.record(
        circleId,
        MeasurementReadingDraft(kind: occurrence.kind, outcome: 'skipped'),
        occurrence: occurrence,
      );
      await reload();
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          MeasurementTasksState(
            status: MeasurementLoadStatus.ready,
            tasks: state.tasks,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
      return false;
    }
  }
}
