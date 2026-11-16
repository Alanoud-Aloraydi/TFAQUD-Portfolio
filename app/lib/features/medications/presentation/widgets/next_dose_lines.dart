import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_text.dart';
import 'package:app/features/medications/presentation/widgets/navigate_to_medication.dart';
import 'package:flutter/material.dart';

/// The medicine of the next dose, tapped to open it, and the dose with its
/// note under the name.
class NextDoseLines extends StatelessWidget {
  const NextDoseLines({
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
    final TextTheme text = Theme.of(context).textTheme;
    final String strength = doseStrengthText(context, occurrence);
    final String dose = formatMedicationDose(
      context,
      occurrence.doseValue,
      occurrence.doseUnit,
    );
    final String how = occurrence.instructions == null
        ? dose
        : '$dose، ${occurrence.instructions}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MergeSemantics(
          child: Semantics(
            button: true,
            child: InkWell(
              onTap: () =>
                  openMedication(context, circleId, occurrence, canManage),
              child: Row(
                children: [
                  const Icon(TafaqodPhosphorIcons.pill, size: 17),
                  const SizedBox(width: AppSpacing.tight),
                  Flexible(
                    child: Text(
                      '${occurrence.name} $strength',
                      style: text.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Text(
          how,
          semanticsLabel: spoken(how),
          textAlign: TextAlign.end,
          style: text.bodyMedium,
        ),
      ],
    );
  }
}
