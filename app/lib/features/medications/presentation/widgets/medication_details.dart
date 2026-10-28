import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MedicationDetails extends StatelessWidget {
  const MedicationDetails({super.key, required this.plan});

  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
    final version = plan.version;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(version.name, style: Theme.of(context).textTheme.headlineSmall),
        Text(
          '${formatMedicationNumber(version.strengthValue)} '
          '${version.strengthUnit.apiValue}',
        ),
        const SizedBox(height: AppSpacing.lg),
        _Value(
          label: 'medications.dosage_form',
          value: context.tr('medications.form.${version.dosageForm.name}'),
        ),
        if (version.reason case final value?)
          _Value(label: 'medications.reason', value: value),
        if (version.instructions case final value?)
          _Value(label: 'medications.instructions', value: value),
        _Value(
          label: 'medications.treatment_period',
          value: _period(context, version.startsOn, version.endsOn),
        ),
        if (plan.isScheduledOn(DateUtils.dateOnly(DateTime.now())))
          _Value(
            label: 'medications.effective_from',
            value: formatMedicationDate(context, version.effectiveFromOn),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.tr('medications.dose_schedules'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final schedule in version.schedules)
          _ScheduleRow(schedule: schedule),
      ],
    );
  }

  String _period(BuildContext context, DateTime start, DateTime? end) {
    if (end == null) {
      return context.tr(
        'medications.starts_on',
        args: [formatMedicationDate(context, start)],
      );
    }
    return context.tr(
      'medications.period',
      args: [
        formatMedicationDate(context, start),
        formatMedicationDate(context, end),
      ],
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(label),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.schedule});

  final MedicationSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final time = formatMedicationTime(context, schedule.time);
    final days = schedule.weekdays
        .map((day) => context.tr('medications.weekday.$day'))
        .join(context.tr('medications.list_separator'));
    final dose = context.tr(
      'medications.dose',
      args: [
        formatMedicationNumber(schedule.doseValue),
        context.tr('medications.unit.${schedule.doseUnit.name}'),
      ],
    );
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.schedule_outlined),
          title: Text('$time · $dose'),
          subtitle: Text(
            [
              days,
              schedule.instructions,
            ].whereType<String>().where((value) => value.isNotEmpty).join('\n'),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
