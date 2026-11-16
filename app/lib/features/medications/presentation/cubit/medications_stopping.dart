import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/cubit/medications_writing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
