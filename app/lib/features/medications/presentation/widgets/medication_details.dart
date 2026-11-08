import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/account/presentation/widgets/settings_card.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
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
              context.tr(
                'medications.missed_option.${version.missedAfterMinutes}',
              ),
            ),
            _value(
              context,
              'medications.treatment_period',
              _period(context, version.startsOn, version.endsOn),
            ),
            if (plan.isScheduledOn(riyadhToday()))
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
              _ScheduleRow(schedule: schedule),
          ],
        ),
      ],
    );
  }

  Widget _value(BuildContext context, String label, String value) =>
      InfoRow(label: context.tr(label), value: value);

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

/// Displays the medication revision history UI.
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

/// Renders the revision entry element of medication details.
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
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.borderSubtle),
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

/// One dose time in the card: the clock, «8:00 ص · 1 قرص», and under it
/// the days and the note, with the rows' 16 side padding.
class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.schedule});

  final MedicationSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final time = formatMedicationTime(context, schedule.time);
    final days = switch (schedule.repeat) {
      ScheduleRepeat.monthly => formatMonthDays(context, schedule.monthDays),
      ScheduleRepeat.interval => formatInterval(
        context,
        schedule.intervalDays ?? 1,
      ),
      ScheduleRepeat.weekly =>
        schedule.weekdays
            .map((day) => context.tr('medications.weekday.$day'))
            .join(context.tr('medications.list_separator')),
    };
    final dose = context.tr(
      'medications.dose',
      args: [
        formatMedicationNumber(schedule.doseValue),
        context.tr('medications.unit.${schedule.doseUnit.name}'),
      ],
    );
    final details = [
      days,
      schedule.instructions,
    ].whereType<String>().where((value) => value.isNotEmpty).join('\n');
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
                  Text('$time · $dose', style: text.bodyLarge),
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
