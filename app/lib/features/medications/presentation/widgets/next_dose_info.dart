import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NextDoseInfo extends StatelessWidget {
  const NextDoseInfo({
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
    final strength = doseStrengthText(context, occurrence);
    final dose = formatMedicationDose(
      context,
      occurrence.doseValue,
      occurrence.doseUnit,
    );
    final formattedTime = clockText(occurrence.time);
    final timeParts = formattedTime.split(' ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeParts.first,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            if (timeParts.length > 1)
              Text(
                timeParts.last,
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => context.push(
                  Routes.medicationDetails(circleId, occurrence.planId),
                  extra: canManage,
                ),
                child: Row(
                  children: [
                    const Icon(TafaqodPhosphorIcons.pill, size: 17),
                    const SizedBox(width: AppSpacing.tight),
                    Flexible(
                      child: Text(
                        '${occurrence.name} $strength',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                occurrence.instructions == null
                    ? dose
                    : '$dose · ${occurrence.instructions}',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
