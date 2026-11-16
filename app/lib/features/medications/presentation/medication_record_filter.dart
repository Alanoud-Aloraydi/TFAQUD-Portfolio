import 'package:app/features/medications/domain/entities/medication_plan.dart';

/// Which plans «السجل» shows: every one, the ones still running, or the
/// ones already behind.
enum MedicationRecordFilter {
  all,
  current,
  previous;

  /// Whether [plan] belongs in the list on [today].
  bool keeps(MedicationPlan plan, DateTime today) => switch (this) {
    all => true,
    current => !plan.isPreviousOn(today),
    MedicationRecordFilter.previous => plan.isPreviousOn(today),
  };

  /// The key of its words, under `medications.filter`.
  String get labelKey => 'medications.filter.$name';
}
