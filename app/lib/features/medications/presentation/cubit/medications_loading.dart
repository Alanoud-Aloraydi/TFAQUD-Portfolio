import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_writing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reading the medicines for the first time, or over again on purpose.
mixin MedicationsLoading on Cubit<MedicationsState>, MedicationsScope {
  /// Reads [circleId]'s medicines. With [silent] the list shown stays while
  /// it is read again, and a failure keeps it.
  Future<void> load(String circleId, {bool silent = false}) async {
    final bool keep =
        silent &&
        this.circleId == circleId &&
        planId == null &&
        state.status == MedicationsStatus.ready;
    this.circleId = circleId;
    planId = null;
    reads = true;
    final revision = ++this.revision;
    if (!keep) {
      emit(
        state.copyWith(status: MedicationsStatus.loading, clearMessage: true),
      );
    }
    final result = await medications.getPlans(circleId);
    if (isClosed || revision != this.revision) return;
    result.when(
      (plans) {
        emit(MedicationsState(status: MedicationsStatus.ready, plans: plans));
      },
      (failure) {
        if (keep) return;
        emit(
          state.copyWith(
            status: MedicationsStatus.failure,
            messageKey: failure.messageKey,
          ),
        );
      },
    );
  }

  /// Reads the one medicine [planId] of [circleId].
  Future<void> loadPlan(String circleId, String planId) async {
    this.circleId = circleId;
    this.planId = planId;
    reads = true;
    final revision = ++this.revision;
    emit(state.copyWith(status: MedicationsStatus.loading, clearMessage: true));
    final result = await medications.getPlan(circleId, planId);
    if (isClosed || revision != this.revision) return;
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
}

/// Ending a medicine, and dropping a change that has not started yet.
mixin MedicationsStopping
    on Cubit<MedicationsState>, MedicationsScope, MedicationsWriting {
  Future<bool> discontinue(MedicationPlan plan) async {
    final circleId = this.circleId;
    if (circleId == null || state.status == MedicationsStatus.saving) {
      return false;
    }
    emit(state.copyWith(status: MedicationsStatus.saving, clearMessage: true));
    // A reading already on its way has the list from before this change.
    revision++;
    final result = await medications.discontinuePlan(circleId, plan.id);
    return replacePlan(result);
  }

  Future<bool> cancelPending(MedicationPlan plan) async {
    final circleId = this.circleId;
    final pending = plan.pendingVersion;
    if (circleId == null ||
        pending == null ||
        state.status == MedicationsStatus.saving) {
      return false;
    }
    emit(state.copyWith(status: MedicationsStatus.saving, clearMessage: true));
    // A reading already on its way has the list from before this change.
    revision++;
    final result = await medications.cancelPendingPlan(
      circleId,
      plan.id,
      pending.number,
    );
    return replacePlan(result);
  }
}
