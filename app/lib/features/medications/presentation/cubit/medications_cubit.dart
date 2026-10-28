import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

class MedicationsCubit extends Cubit<MedicationsState> {
  MedicationsCubit(this._medications) : super(MedicationsState());

  final MedicationsUseCase _medications;
  String? _circleId;
  int _revision = 0;

  void bind(String circleId) {
    _circleId = circleId;
  }

  Future<void> load(String circleId) async {
    _circleId = circleId;
    final revision = ++_revision;
    emit(state.copyWith(status: MedicationsStatus.loading, clearMessage: true));
    final result = await _medications.getPlans(circleId);
    if (isClosed || revision != _revision) return;
    result.when(
      (plans) {
        emit(
          MedicationsState(
            status: MedicationsStatus.ready,
            plans: plans,
            recordFilter: state.recordFilter,
          ),
        );
      },
      (failure) {
        emit(
          state.copyWith(
            status: MedicationsStatus.failure,
            messageKey: failure.messageKey,
          ),
        );
      },
    );
  }

  Future<void> loadPlan(String circleId, String planId) async {
    _circleId = circleId;
    final revision = ++_revision;
    emit(state.copyWith(status: MedicationsStatus.loading, clearMessage: true));
    final result = await _medications.getPlan(circleId, planId);
    if (isClosed || revision != _revision) return;
    result.when(
      (plan) => emit(
        MedicationsState(status: MedicationsStatus.ready, plans: [plan]),
      ),
      (failure) => emit(
        MedicationsState(
          status: MedicationsStatus.failure,
          messageKey: failure.messageKey,
        ),
      ),
    );
  }

  Future<bool> create(MedicationPlanDraft draft) async {
    final circleId = _circleId;
    if (circleId == null || state.status == MedicationsStatus.saving) {
      return false;
    }
    emit(state.copyWith(status: MedicationsStatus.saving, clearMessage: true));
    final result = await _medications.createPlan(circleId, draft);
    if (isClosed) return false;
    return result.when(
      (plan) {
        emit(
          MedicationsState(
            status: MedicationsStatus.ready,
            plans: [...state.plans, plan],
            recordFilter: state.recordFilter,
          ),
        );
        return true;
      },
      (failure) {
        emit(
          state.copyWith(
            status: MedicationsStatus.ready,
            messageKey: failure.messageKey,
          ),
        );
        return false;
      },
    );
  }

  Future<bool> revise(MedicationPlan plan, MedicationPlanDraft draft) async {
    final circleId = _circleId;
    if (circleId == null || state.status == MedicationsStatus.saving) {
      return false;
    }
    emit(state.copyWith(status: MedicationsStatus.saving, clearMessage: true));
    final result = await _medications.revisePlan(
      circleId,
      plan.id,
      plan.version.number,
      draft,
    );
    return _replace(result);
  }

  Future<bool> discontinue(MedicationPlan plan) async {
    final circleId = _circleId;
    if (circleId == null || state.status == MedicationsStatus.saving) {
      return false;
    }
    emit(state.copyWith(status: MedicationsStatus.saving, clearMessage: true));
    final result = await _medications.discontinuePlan(circleId, plan.id);
    return _replace(result);
  }

  bool _replace(Result<MedicationPlan, Failure> result) {
    if (isClosed) return false;
    return result.when(
      (MedicationPlan changed) {
        final plans = [
          for (final plan in state.plans)
            if (plan.id == changed.id) changed else plan,
        ];
        emit(
          MedicationsState(
            status: MedicationsStatus.ready,
            plans: plans,
            recordFilter: state.recordFilter,
          ),
        );
        return true;
      },
      (failure) {
        emit(
          state.copyWith(
            status: MedicationsStatus.ready,
            messageKey: failure.messageKey,
          ),
        );
        return false;
      },
    );
  }

  void setRecordFilter(MedicationRecordFilter filter) {
    if (filter == state.recordFilter) return;
    emit(state.copyWith(recordFilter: filter));
  }
}
