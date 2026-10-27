import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:equatable/equatable.dart';

enum MedicationsStatus { initial, loading, ready, saving, failure }

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
