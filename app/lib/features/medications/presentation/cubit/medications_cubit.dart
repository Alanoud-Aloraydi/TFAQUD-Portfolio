import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medications_scope.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

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
