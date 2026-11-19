import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:equatable/equatable.dart';

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
