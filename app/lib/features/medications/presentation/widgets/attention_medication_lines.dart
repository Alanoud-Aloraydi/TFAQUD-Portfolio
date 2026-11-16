import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/attention_dose_pill.dart';
import 'package:app/features/medications/presentation/widgets/attention_dose_text.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_text.dart';
import 'package:app/features/medications/presentation/widgets/navigate_to_medication.dart';
import 'package:flutter/material.dart';

/// A late dose of «يحتاج انتباهك»: the pill, then the three lines, read in
/// one breath and opening with the medicine, and tapped to open it.
class AttentionMedicationLines extends StatelessWidget {
  const AttentionMedicationLines({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.canManage,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final String dose = formatMedicationDose(
      context,
      occurrence.doseValue,
      occurrence.doseUnit,
    );
    final String title =
        '${occurrence.name} ${doseStrengthText(context, occurrence)}';
    final String when =
        '${formatMedicationDate(context, occurrence.scheduledOn)}'
        '، ${clockText(occurrence.time)}';
    final String how = occurrence.instructions == null
        ? dose
        : '$dose، ${occurrence.instructions}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AttentionDosePill(),
        const SizedBox(width: AppSpacing.tight),
        Expanded(
          child: MergeSemantics(
            child: Semantics(
              button: true,
              label: spoken('$title، $when، $how'),
              child: InkWell(
                onTap: () =>
                    openMedication(context, circleId, occurrence, canManage),
                child: ExcludeSemantics(
                  child: AttentionDoseText(title: title, when: when, how: how),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
