import 'dart:async';

import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medications_loading.dart';
import 'package:app/features/medications/presentation/cubit/medications_scope.dart';
import 'package:app/features/medications/presentation/cubit/medications_writing.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The medicines of one circle, and their changes.
///
/// The home tabs hold one; the medicine pages hold their own. A cubit that
/// read the list ([load]) or one medicine ([loadPlan]) reads it again
/// whenever [MedicationsUseCase.changes] says the circle's medicines
/// changed, wherever the change was saved, so they never disagree. A cubit
/// that only [bind]s a circle (the new-medicine form) shows what it saved
/// and follows nothing.
class MedicationsCubit extends Cubit<MedicationsState>
    with
        MedicationsScope,
        MedicationsLoading,
        MedicationsRefresh,
        MedicationsWriting,
        MedicationsRevising,
        MedicationsStopping {
  MedicationsCubit(this.medications) : super(MedicationsState()) {
    _changes = medications.changes.listen(_onChanged);
  }

  @override
  final MedicationsUseCase medications;

  late final StreamSubscription<String> _changes;

  void _onChanged(String circleId) {
    if (reads && circleId == this.circleId) unawaited(reread());
  }

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}

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

enum MedicationsStatus { initial, loading, ready, saving, failure }

/// The medicines on screen, and whether one is being saved.
class MedicationsState extends Equatable {
  MedicationsState({
    this.status = MedicationsStatus.initial,
    List<MedicationPlan> plans = const [],
    this.messageKey,
  }) : plans = List.unmodifiable(plans);

  final MedicationsStatus status;
  final List<MedicationPlan> plans;
  final String? messageKey;

  MedicationsState copyWith({
    MedicationsStatus? status,
    List<MedicationPlan>? plans,
    String? messageKey,
    bool clearMessage = false,
  }) => MedicationsState(
    status: status ?? this.status,
    plans: plans ?? this.plans,
    messageKey: clearMessage ? null : (messageKey ?? this.messageKey),
  );

  @override
  List<Object?> get props => [status, plans, messageKey];
}
