import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/cubit/medications_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// Adding a medicine, and putting the server's answer in the list. Every
/// change starts by saying it is being saved, so the list never shows a
/// change the server did not take.
mixin MedicationsWriting on Cubit<MedicationsState>, MedicationsScope {
  Future<bool> create(MedicationPlanDraft draft) async {
    final circleId = this.circleId;
    if (circleId == null || state.status == MedicationsStatus.saving) {
      return false;
    }
    emit(state.copyWith(status: MedicationsStatus.saving, clearMessage: true));
    // A reading already on its way has the list from before this change.
    revision++;
    final result = await medications.createPlan(circleId, draft);
    if (isClosed) return false;
    return result.when(
      (plan) {
        emit(
          MedicationsState(
            status: MedicationsStatus.ready,
            plans: [...state.plans, plan],
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

  /// Puts the medicine the server answered with in place of the one shown.
  bool replacePlan(Result<MedicationPlan, Failure> result) {
    if (isClosed) return false;
    return result.when(
      (MedicationPlan changed) {
        final plans = [
          for (final plan in state.plans)
            if (plan.id == changed.id) changed else plan,
        ];
        emit(MedicationsState(status: MedicationsStatus.ready, plans: plans));
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
}
