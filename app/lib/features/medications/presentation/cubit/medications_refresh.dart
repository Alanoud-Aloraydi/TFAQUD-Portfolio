import 'package:app/features/medications/presentation/cubit/medications_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
