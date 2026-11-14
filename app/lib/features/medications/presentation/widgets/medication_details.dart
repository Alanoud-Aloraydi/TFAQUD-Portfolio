import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/info_row.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/settings_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(version.name, style: Theme.of(context).textTheme.headlineSmall),
        Text(
          '${formatMedicationNumber(version.strengthValue)} '
          '${context.tr('medications.strength_display.${version.strengthUnit.name}')}',
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsCard(
          children: [
            _value(
              context,
              'medications.dosage_form',
              context.tr('medications.form.${version.dosageForm.name}'),
            ),
            if (version.reason case final value?)
              _value(context, 'medications.reason', value),
            if (version.instructions case final value?)
              _value(context, 'medications.instructions', value),
            _value(
              context,
              'medications.missed_after',
              arabicCount(
                context,
                ArabicCount.minutes,
                version.missedAfterMinutes,
              ),
            ),
            _value(
              context,
              'medications.treatment_period',
              formatMedicationPeriod(
                context,
                version.startsOn,
                version.endsOn,
                today: PatientClockScope.of(context).today(),
              ),
            ),
            if (plan.isScheduledOn(PatientClockScope.of(context).today()))
              _value(
                context,
                'medications.effective_from',
                formatMedicationDate(context, version.effectiveFromOn),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        InsetGroup(
          header: context.tr('medications.dose_schedules'),
          children: [
            for (final schedule in version.schedules)
              MedicationScheduleRow(schedule: schedule),
          ],
        ),
      ],
    );
  }

  Widget _value(BuildContext context, String label, String value) =>
      InfoRow(label: context.tr(label), value: value);
}
