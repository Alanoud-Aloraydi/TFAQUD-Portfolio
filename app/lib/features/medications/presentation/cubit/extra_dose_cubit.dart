import 'package:app/core/errors/failure.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/usecases/medications_use_case.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// «سجّل جرعة الآن» of [circleId]: reads its medicines, then sends one
/// extra dose.
class ExtraDoseCubit extends Cubit<ExtraDoseState> {
  ExtraDoseCubit(this._medications, this.circleId)
    : super(const ExtraDoseState());

  final MedicationsUseCase _medications;
  final String circleId;

  Future<void> load() async {
    emit(const ExtraDoseState());
    final result = await _medications.getPlans(circleId);
    if (isClosed) return;
    result.when(
      (List<MedicationPlan> plans) => emit(ExtraDoseState(plans: plans)),
      (Failure failure) =>
          emit(ExtraDoseState(loadErrorKey: failure.messageKey)),
    );
  }

  /// True when the server kept it. A tap while it is on its way sends
  /// nothing.
  Future<bool> record(ExtraDoseDraft draft) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true));
    final result = await _medications.recordExtraDose(circleId, draft);
    if (isClosed) return false;
    return result.when(
      (ExtraDose _) {
        emit(state.copyWith(saving: false));
        return true;
      },
      (Failure failure) {
        emit(state.copyWith(saving: false, errorKey: failure.messageKey));
        return false;
      },
    );
  }

  /// A change in the sheet: the last error no longer applies.
  void clearError() {
    if (state.errorKey != null) emit(state.copyWith());
  }
}

/// «سجّل جرعة الآن»: the circle's medicines to choose from, and the dose
/// while it is sent.
class ExtraDoseState extends Equatable {
  const ExtraDoseState({
    this.plans,
    this.loadErrorKey,
    this.saving = false,
    this.errorKey,
  });

  /// Null while they load.
  final List<MedicationPlan>? plans;

  /// Why they did not load: a key in assets/translations.
  final String? loadErrorKey;
  final bool saving;

  /// Why the last save failed: a key in assets/translations.
  final String? errorKey;

  ExtraDoseState copyWith({
    List<MedicationPlan>? plans,
    bool? saving,
    String? errorKey,
  }) => ExtraDoseState(
    plans: plans ?? this.plans,
    loadErrorKey: loadErrorKey,
    saving: saving ?? this.saving,
    errorKey: errorKey,
  );

  @override
  List<Object?> get props => [plans, loadErrorKey, saving, errorKey];
}
