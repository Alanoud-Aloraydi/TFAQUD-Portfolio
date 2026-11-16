import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:app/features/medications/presentation/cubit/medications_writing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Changing a medicine that is already in use.
mixin MedicationsRevising
    on Cubit<MedicationsState>, MedicationsScope, MedicationsWriting {
  Future<bool> revise(MedicationPlan plan, MedicationPlanDraft draft) async {
    final circleId = this.circleId;
    if (circleId == null || state.status == MedicationsStatus.saving) {
      return false;
    }
    emit(state.copyWith(status: MedicationsStatus.saving, clearMessage: true));
    // A reading already on its way has the list from before this change.
    revision++;
    // The latest version: a change waiting for later is the one replaced.
    final result = await medications.revisePlan(
      circleId,
      plan.id,
      (plan.pendingVersion ?? plan.version).number,
      draft,
    );
    return replacePlan(result);
  }
}
