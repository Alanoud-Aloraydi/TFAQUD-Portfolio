import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/presentation/widgets/emergency_card_text.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:flutter/material.dart';

class EmergencyMedicine extends StatelessWidget {
  const EmergencyMedicine({super.key, required this.plan, required this.words});

  final MedicationPlan plan;
  final EmergencyCardText words;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? small = text.bodySmall?.copyWith(
      color: AppSemanticColors.textSupporting,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(plan.version.name, style: text.titleSmall),
                // The strength is its own run, left to right, so «500 mg»
                // never turns into «mg 500».
                Wrap(
                  spacing: AppSpacing.xs,
                  children: <Widget>[
                    Text(
                      '${formatMedicationNumber(plan.version.strengthValue)} '
                      '${plan.version.strengthUnit.apiValue}',
                      textDirection: TextDirection.ltr,
                      style: small,
                    ),
                    Text('·', style: small),
                    Text(
                      words.form(plan.version.dosageForm.name),
                      style: small,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (final schedule in plan.version.schedules)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      words.clock(schedule.time),
                      textDirection: TextDirection.ltr,
                      style: small,
                    ),
                    // «8:00 ص · 1 قرص»: a dot keeps the time and the dose
                    // apart.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Text('·', style: small),
                    ),
                    Text(
                      '${formatMedicationNumber(schedule.doseValue)} '
                      '${words.unit(schedule.doseUnit.name)}',
                      style: small,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
