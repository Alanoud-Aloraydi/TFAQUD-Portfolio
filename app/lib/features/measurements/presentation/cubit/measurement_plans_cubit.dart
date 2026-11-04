import 'package:app/core/errors/network_exceptions.dart';
import 'package:app/features/measurements/data/measurement_repository.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Coordinates measurement plans actions and UI state.
class MeasurementPlansCubit extends Cubit<MeasurementPlansState> {
  MeasurementPlansCubit(this._repository)
    : super(const MeasurementPlansState());

  final MeasurementRepository _repository;
  String? _circleId;
  int _revision = 0;

  Future<void> load(String circleId) async {
    final changedCircle = _circleId != circleId;
    _circleId = circleId;
    final revision = ++_revision;
    emit(
      MeasurementPlansState(
        status: MeasurementLoadStatus.loading,
        plans: changedCircle ? const [] : state.plans,
      ),
    );
    try {
      final plans = await _repository.plans(circleId);
      if (isClosed || revision != _revision) return;
      emit(
        MeasurementPlansState(
          status: MeasurementLoadStatus.ready,
          plans: plans,
        ),
      );
    } catch (error) {
      if (isClosed || revision != _revision) return;
      emit(
        MeasurementPlansState(
          status: MeasurementLoadStatus.failure,
          plans: state.plans,
          errorKey: FailureExceptions.getException(error).messageKey,
        ),
      );
    }
  }

  Future<bool> create(MeasurementPlanDraft draft) =>
      _write((circleId) => _repository.createPlan(circleId, draft));

  Future<bool> revise(MeasurementPlan plan, MeasurementPlanDraft draft) =>
      _write((circleId) => _repository.revisePlan(circleId, plan, draft));

  Future<bool> stop(MeasurementPlan plan) =>
      _write((circleId) => _repository.stopPlan(circleId, plan.id));

  Future<bool> _write(
    Future<MeasurementPlan> Function(String circleId) operation,
  ) async {
    final circleId = _circleId;
    if (circleId == null) return false;
    try {
      await operation(circleId);
      if (!isClosed) await load(circleId);
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          MeasurementPlansState(
            status: MeasurementLoadStatus.ready,
            plans: state.plans,
            errorKey: FailureExceptions.getException(error).messageKey,
          ),
        );
      }
      return false;
    }
  }
}
