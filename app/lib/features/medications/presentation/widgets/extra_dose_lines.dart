import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/fact_pill.dart';
import 'package:app/features/medications/domain/entities/dose_history_entry.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_heading.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_text.dart';
import 'package:flutter/material.dart';

/// The words of an extra dose in the history, as a dose of a dose time
/// has them: the time it was taken right above the medicine, whose
/// strength and dose sit beside its name in small pills.
class ExtraDoseLines extends StatelessWidget {
  const ExtraDoseLines({super.key, required this.entry});

  final ExtraDoseEntry entry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      DoseHistoryHeading.taken(takenAt: entry.dose.takenAt),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            entry.medicine.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          FactPill(
            strengthText(
              context,
              entry.medicine.strengthValue,
              entry.medicine.strengthUnit,
            ),
          ),
          FactPill(
            formatMedicationDose(
              context,
              entry.dose.doseValue,
              entry.dose.doseUnit,
            ),
          ),
        ],
      ),
    ],
  );
}
