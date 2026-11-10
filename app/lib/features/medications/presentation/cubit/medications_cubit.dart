import 'dart:async';

import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/use_cases/medications_use_case.dart';
import 'package:app/features/medications/presentation/cubit/medications_state.dart';
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
class MedicationsCubit extends Cubit<MedicationsState> {
  MedicationsCubit(this._medications) : super(MedicationsState()) {
    _changes = _medications.changes.listen(_onChanged);
  }

  final MedicationsUseCase _medications;
  late final StreamSubscription<String> _changes;
  String? _circleId;

  /// The one medicine this cubit shows, or null for the whole list.
  String? _planId;

  /// Whether this cubit read something, so it has something to keep fresh.
  bool _reads = false;
  int _revision = 0;

  /// Sets the circle for a cubit that only saves (no list is read).
  void bind(String circleId) {
    _circleId = circleId;
  }

  void _onChanged(String circleId) {
    if (_reads && circleId == _circleId) unawaited(_reread());
  }

  /// Reads again what is shown, without the loading state. A failure keeps
  /// what is on screen, unless nothing arrived yet. While a change of this
  /// cubit is being sent, its own answer updates the list instead.
  Future<void> _reread() async {
    final String circleId = _circleId!;
    final String? planId = _planId;
    if (state.status == MedicationsStatus.saving) return;
    final revision = ++_revision;
    final result = await _read(circleId, planId);
    if (isClosed ||
        revision != _revision ||
        state.status == MedicationsStatus.saving) {
      return;
    }
    result.when(
      (plans) => emit(
        MedicationsState(
          status: MedicationsStatus.ready,
          plans: plans,
          recordFilter: state.recordFilter,
        ),
      ),
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

  /// The medicines to show: the list, or just [planId] when it is given.
  Future<Result<List<MedicationPlan>, Failure>> _read(
    String circleId,
    String? planId,
  ) async {
    if (planId == null) return _medications.getPlans(circleId);
    final result = await _medications.getPlan(circleId, planId);
    final MedicationPlan? plan = result.tryGetSuccess();
    return plan == null ? Error(result.tryGetError()!) : Success([plan]);
  }

  /// Reads [circleId]'s medicines. With [silent] the list shown stays while
  /// it is read again, and a failure keeps it.
  Future<void> load(String circleId, {bool silent = false}) async {
    final bool keep =
        silent &&
        _circleId == circleId &&
        _planId == null &&
        state.status == MedicationsStatus.ready;
    _circleId = circleId;
    _planId = null;
    _reads = true;
    final revision = ++_revision;
    if (!keep) {
      emit(
        state.copyWith(status: MedicationsStatus.loading, clearMessage: true),
      );
    }
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
    _circleId = circleId;
    _planId = planId;
    _reads = true;
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
    // A reading already on its way has the list from before this change.
    _revision++;
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
    // A reading already on its way has the list from before this change.
    _revision++;
    // The latest version: a change waiting for later is the one replaced.
    final result = await _medications.revisePlan(
      circleId,
      plan.id,
      (plan.pendingVersion ?? plan.version).number,
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
    // A reading already on its way has the list from before this change.
    _revision++;
    final result = await _medications.discontinuePlan(circleId, plan.id);
    return _replace(result);
  }

  Future<bool> cancelPending(MedicationPlan plan) async {
    final circleId = _circleId;
    final pending = plan.pendingVersion;
    if (circleId == null ||
        pending == null ||
        state.status == MedicationsStatus.saving) {
      return false;
    }
    emit(state.copyWith(status: MedicationsStatus.saving, clearMessage: true));
    // A reading already on its way has the list from before this change.
    _revision++;
    final result = await _medications.cancelPendingPlan(
      circleId,
      plan.id,
      pending.number,
    );
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

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
