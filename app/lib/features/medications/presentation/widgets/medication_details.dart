import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
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
          '${context.tr('medications.strength_display.${version.strengthUnit.name}')}',
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
          label: 'medications.missed_after',
          value: context.tr(
            'medications.missed_option.${version.missedAfterMinutes}',
          ),
        ),
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

class MedicationRevisionHistory extends StatelessWidget {
  const MedicationRevisionHistory({super.key, required this.plan});

  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
    final history = plan.history.isEmpty ? [plan.version] : plan.history;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('medications.revision_history'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        for (var index = history.length - 1; index >= 0; index--) ...[
          _RevisionEntry(
            version: history[index],
            previous: index == 0 ? null : history[index - 1],
          ),
          if (index > 0) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _RevisionEntry extends StatelessWidget {
  const _RevisionEntry({required this.version, required this.previous});

  final MedicationVersion version;
  final MedicationVersion? previous;

  @override
  Widget build(BuildContext context) {
    final date = formatMedicationDate(context, version.effectiveFromOn);
    final before = previous == null ? null : _scheduleText(context, previous!);
    final after = _scheduleText(context, version);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfacePlan,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              previous == null
                  ? 'medications.initial_version'
                  : 'medications.revised_on',
              args: [date],
            ),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${version.name} · '
            '${formatMedicationNumber(version.strengthValue)} '
            '${context.tr('medications.strength_display.${version.strengthUnit.name}')} · '
            '${context.tr('medications.form.${version.dosageForm.name}')}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('medications.schedule_revision'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (before != null && before != after)
            Text(
              before,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(decoration: TextDecoration.lineThrough),
            ),
          Text(after, style: Theme.of(context).textTheme.bodyMedium),
          if (version.reason case final reason?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(reason, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (version.instructions case final instructions?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(instructions, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  String _scheduleText(BuildContext context, MedicationVersion item) => item
      .schedules
      .map((schedule) {
        final dose = context.tr(
          'medications.dose',
          args: [
            formatMedicationNumber(schedule.doseValue),
            context.tr('medications.unit.${schedule.doseUnit.name}'),
          ],
        );
        return '${formatMedicationTime(context, schedule.time)} · $dose';
      })
      .join('، ');
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
          leading: const Icon(CupertinoIcons.clock),
          title: Text('$time · $dose'),
          subtitle: Text(
            [
              days,
              schedule.instructions,
            ].whereType<String>().where((value) => value.isNotEmpty).join('\n'),
          ),
        ),
        const Divider(height: AppSizes.divider),
      ],
    );
  }
}
