import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/settings_card.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/medication_fact_rows.dart';
import 'package:app/features/medications/presentation/widgets/medication_schedule_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The details of a medicine, laid out like the medical file: the name and
/// the strength as the title, then the facts in a white card, then the dose
/// times in a grouped card under a small header. The cards reach the edges
/// and the text inside them starts 16 in.
class MedicationDetails extends StatelessWidget {
  const MedicationDetails({super.key, required this.plan});

  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
    final version = plan.version;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(version.name, style: Theme.of(context).textTheme.headlineSmall),
          Text(
            '${formatMedicationNumber(version.strengthValue)} '
            '${context.tr('medications.strength_display.${version.strengthUnit.name}')}',
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsCard(children: medicationFactRows(context, plan)),
          const SizedBox(height: AppSpacing.xl),
          InsetGroup(
            header: context.tr('medications.dose_schedules'),
            children: [
              for (final schedule in version.schedules)
                MedicationScheduleRow(schedule: schedule),
            ],
          ),
        ],
      ),
    );
  }
}
