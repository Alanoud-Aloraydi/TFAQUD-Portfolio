import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
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
        if (version.strength case final value?) Text(value),
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
    final format = DateFormat.yMd(context.locale.toString());
    if (end == null) {
      return context.tr('medications.starts_on', args: [format.format(start)]);
    }
    return context.tr(
      'medications.period',
      args: [format.format(start), format.format(end)],
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
    final time = DateFormat.jm(context.locale.toString())
        .format(DateTime.parse('2000-01-01T${schedule.time}'));
    final days = schedule.weekdays
        .map((day) => context.tr('medications.weekday.$day'))
        .join(context.tr('medications.list_separator'));
    final dose = context.tr(
      'medications.dose',
      args: [
        schedule.doseValue.toString().replaceFirst(RegExp(r'\.0$'), ''),
        context.tr('medications.unit.${schedule.doseUnit.name}'),
      ],
    );
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule_outlined),
        title: Text('$time · $dose'),
        subtitle: Text(
          [
            days,
            schedule.instructions,
          ].whereType<String>().where((value) => value.isNotEmpty).join('\n'),
        ),
      ),
    );
  }
}
