import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_text.dart';
import 'package:flutter/material.dart';

/// One dose time in the card: the clock, «8:00 ص، 1 قرص», and under it
/// the days and the note, with the rows' 16 side padding.
class MedicationScheduleRow extends StatelessWidget {
  const MedicationScheduleRow({super.key, required this.schedule});

  final MedicationSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String time = clockText(schedule.time);
    final String dose = formatMedicationDose(
      context,
      schedule.doseValue,
      schedule.doseUnit,
    );
    final String details = scheduleDetailsText(context, schedule);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inset,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppIcons.clock,
              size: AppSizes.iconSmall,
              color: context.tokens.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$time، $dose',
                    style: text.bodyLarge,
                    semanticsLabel: spoken('$time، $dose'),
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      details,
                      style: text.bodySmall?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
