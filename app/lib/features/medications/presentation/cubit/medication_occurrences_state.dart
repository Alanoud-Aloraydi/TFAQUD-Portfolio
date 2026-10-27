import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:equatable/equatable.dart';

enum MedicationOccurrencesStatus {
  loading,
  loadingMore,
  ready,
  recording,
  failure,
}

class MedicationOccurrencesState extends Equatable {
  MedicationOccurrencesState({
    this.status = MedicationOccurrencesStatus.loading,
    List<DoseOccurrence> occurrences = const [],
    this.messageKey,
  }) : occurrences = List.unmodifiable(occurrences);

  final MedicationOccurrencesStatus status;
  final List<DoseOccurrence> occurrences;
  final String? messageKey;

  @override
  List<Object?> get props => [status, occurrences, messageKey];
}
