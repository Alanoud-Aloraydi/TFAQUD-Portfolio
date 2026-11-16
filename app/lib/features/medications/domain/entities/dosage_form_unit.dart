import 'package:app/features/medications/domain/entities/dosage_form.dart';
import 'package:app/features/medications/domain/entities/dose_unit.dart';

/// Adds dosage form unit helpers to its target type.
extension DosageFormUnit on DosageForm {
  List<DoseUnit> get doseUnits => switch (this) {
    DosageForm.tablet => const [DoseUnit.tablet],
    DosageForm.capsule => const [DoseUnit.capsule],
    DosageForm.liquid => const [DoseUnit.milliliter],
    DosageForm.drops => const [DoseUnit.drop],
    DosageForm.inhaler => const [DoseUnit.puff],
    DosageForm.nebulizer => const [DoseUnit.milliliter],
    DosageForm.injection => const [DoseUnit.milliliter, DoseUnit.unit],
  };

  DoseUnit get defaultDoseUnit => doseUnits.first;
}
