import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

/// What a medicines cubit is pointed at, shared by everything it does: the
/// circle, the one medicine when it shows only one, and the revision that
/// tells a stale answer from the newest one.
mixin MedicationsScope on Cubit<MedicationsState> {
  /// The use case the cubit was made with.
  MedicationsUseCase get medications;

  /// The circle whose medicines are shown.
  String? circleId;

  /// The one medicine this cubit shows, or null for the whole list.
  String? planId;

  /// Whether this cubit read something, so it has something to keep fresh.
  bool reads = false;

  /// Counts the readings, so a slower one cannot overwrite a newer answer.
  int revision = 0;

  /// Sets the circle for a cubit that only saves (no list is read).
  void bind(String circleId) {
    this.circleId = circleId;
  }

  /// The medicines to show: the list, or just [planId] when it is given.
  Future<Result<List<MedicationPlan>, Failure>> readPlans(
    String circleId,
    String? planId,
  ) async {
    if (planId == null) return medications.getPlans(circleId);
    final result = await medications.getPlan(circleId, planId);
    final MedicationPlan? plan = result.tryGetSuccess();
    return plan == null ? Error(result.tryGetError()!) : Success([plan]);
  }
}

/// Keeping what is on screen fresh when the circle's medicines change
/// somewhere else.
mixin MedicationsRefresh on Cubit<MedicationsState>, MedicationsScope {
  /// Reads again what is shown, without the loading state. A failure keeps
  /// what is on screen, unless nothing arrived yet. While a change of this
  /// cubit is being sent, its own answer updates the list instead.
  Future<void> reread() async {
    final String circleId = this.circleId!;
    final String? planId = this.planId;
    if (state.status == MedicationsStatus.saving) return;
    final revision = ++this.revision;
    final result = await readPlans(circleId, planId);
    if (isClosed ||
        revision != this.revision ||
        state.status == MedicationsStatus.saving) {
      return;
    }
    result.when(
      (plans) =>
          emit(MedicationsState(status: MedicationsStatus.ready, plans: plans)),
      (failure) {
        if (state.status == MedicationsStatus.loading) {
          emit(
            state.copyWith(
              status: MedicationsStatus.failure,
              messageKey: failure.messageKey,
            ),
          );
        }
      },
    );
  }
}
