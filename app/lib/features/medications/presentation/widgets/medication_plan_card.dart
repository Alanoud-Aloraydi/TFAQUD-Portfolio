import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/home/presentation/cubit/home_cubit.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MedicationPlanCard extends StatefulWidget {
  const MedicationPlanCard({
    super.key,
    required this.circleId,
    required this.plan,
  });

  final String circleId;
  final MedicationPlan plan;

  @override
  State<MedicationPlanCard> createState() => _MedicationPlanCardState();
}

class _MedicationPlanCardState extends State<MedicationPlanCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final version = plan.version;
    final subtitle = [
      '${formatMedicationNumber(version.strengthValue)} '
          '${version.strengthUnit.apiValue}',
      context.tr('medications.form.${version.dosageForm.name}'),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    final today = DateUtils.dateOnly(DateTime.now());
    final status = plan.isPreviousOn(today)
        ? _PlanState.previous
        : plan.isScheduledOn(today)
        ? _PlanState.scheduled
        : _PlanState.current;
    final canManage = context.select<HomeCubit, bool>(
      (cubit) =>
          cubit.state.data?.circles.any(
            (circle) =>
                circle.id == widget.circleId && circle.canManageMedications,
          ) ??
          false,
    );
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: status == _PlanState.current
            ? AppSemanticColors.surfacePlan
            : AppSemanticColors.surfaceContent,
        shape: AppSurfaces.cardShape(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSizes.touch),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.capsule,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        version.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _PlanStatus(state: status),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      _expanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: AppSizes.iconSmall,
                      color: AppSemanticColors.borderControlBase,
                    ),
                  ],
                ),
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle),
            ],
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: status == _PlanState.current
                    ? AppSemanticColors.surfaceContent
                    : AppSemanticColors.surfacePlan,
                borderRadius: BorderRadius.circular(AppRadius.field),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  children: [
                    for (final schedule in version.schedules)
                      _ScheduleLine(schedule: schedule),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            _InfoLine(
              icon: CupertinoIcons.calendar,
              text: _period(context, version.startsOn, version.endsOn),
            ),
            if (plan.pendingVersion case final pending?) ...[
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppSemanticColors.textSupporting,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    [
                      context.tr(
                        'medications.pending_revision',
                        args: [
                          formatMedicationDate(
                            context,
                            pending.effectiveFromOn,
                          ),
                        ],
                      ),
                      if (version.schedules.length == 1 &&
                          pending.schedules.length == 1 &&
                          version.schedules.first.doseUnit ==
                              pending.schedules.first.doseUnit &&
                          version.schedules.first.doseValue !=
                              pending.schedules.first.doseValue)
                        context.tr(
                          'medications.pending_dose_change',
                          args: [
                            formatMedicationNumber(
                              version.schedules.first.doseValue,
                            ),
                            formatMedicationNumber(
                              pending.schedules.first.doseValue,
                            ),
                            context.tr(
                              'medications.unit.${pending.schedules.first.doseUnit.name}',
                            ),
                          ],
                        ),
                    ].join('\n'),
                  ),
                ),
              ),
            ],
            Row(
              children: [
                const Icon(CupertinoIcons.clock, size: AppSizes.iconSmall),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.tr(
                      'medications.missed_footer',
                      args: [
                        context.tr(
                          'medications.missed_option.${version.missedAfterMinutes}',
                        ),
                      ],
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(context.tr('medications.details')),
                ),
              ],
            ),
            if (_expanded) ...[
              const Divider(),
              if (version.reason case final reason?)
                _DetailValue(
                  label: context.tr('medications.reason'),
                  value: reason,
                ),
              if (version.instructions case final instructions?)
                _DetailValue(
                  label: context.tr('medications.instructions'),
                  value: instructions,
                ),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  TextButton(
                    onPressed: () => _openDetails(context),
                    child: Text(context.tr('medications.dose_history')),
                  ),
                  if (canManage &&
                      status == _PlanState.current &&
                      plan.pendingVersion == null)
                    TextButton(
                      onPressed: () => _edit(context),
                      child: Text(context.tr('medications.edit_title')),
                    ),
                  if (canManage && status != _PlanState.previous)
                    TextButton(
                      onPressed: () => _discontinue(context),
                      child: Text(context.tr('medications.discontinue')),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openDetails(BuildContext context) async {
    final changed = await context.push<bool>(
      Routes.medicationDetails(widget.circleId, widget.plan.id),
    );
    if (!context.mounted) return;
    final updates = <Future<void>>[
      context.read<MedicationOccurrencesCubit>().reload(),
    ];
    if (changed == true) {
      updates.add(context.read<MedicationsCubit>().load(widget.circleId));
    }
    await Future.wait(updates);
  }

  Future<void> _edit(BuildContext context) async {
    final changed = await context.push<bool>(
      Routes.editMedication(widget.circleId, widget.plan.id),
    );
    if (changed != true || !context.mounted) return;
    await Future.wait([
      context.read<MedicationsCubit>().load(widget.circleId),
      context.read<MedicationOccurrencesCubit>().reload(),
    ]);
  }

  Future<void> _discontinue(BuildContext context) async {
    final confirmed = await showAppAlert<bool>(
      context,
      title: context.tr('medications.discontinue_title'),
      message: context.tr('medications.discontinue_message'),
      actions: [
        AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
        AppAlertAction<bool>(
          label: context.tr('medications.discontinue_confirm'),
          value: true,
          destructive: true,
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    final changed = await context.read<MedicationsCubit>().discontinue(
      widget.plan,
    );
    if (!context.mounted) return;
    if (changed) {
      await Future.wait([
        context.read<MedicationsCubit>().load(widget.circleId),
        context.read<MedicationOccurrencesCubit>().reload(),
      ]);
      return;
    }
    final message = context.read<MedicationsCubit>().state.messageKey;
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(message))));
    }
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

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label)),
        Expanded(child: Text(value, textAlign: TextAlign.start)),
      ],
    ),
  );
}

class _ScheduleLine extends StatelessWidget {
  const _ScheduleLine({required this.schedule});

  final MedicationSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final time = formatMedicationTime(context, schedule.time);
    final dose = context.tr(
      'medications.dose',
      args: [
        formatMedicationNumber(schedule.doseValue),
        context.tr('medications.unit.${schedule.doseUnit.name}'),
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(time, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(dose)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (final day in const [6, 7, 1, 2, 3, 4, 5]) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: schedule.weekdays.contains(day)
                        ? AppSemanticColors.selectedSurface
                        : AppSemanticColors.surfaceContent,
                    border: schedule.weekdays.contains(day)
                        ? null
                        : Border.all(color: AppSemanticColors.borderSubtle),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: AppSizes.iconSmall,
                    height: AppSizes.iconSmall,
                    child: Center(
                      child: Text(
                        context.tr('medications.weekday_short.$day'),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

enum _PlanState { current, scheduled, previous }

class _PlanStatus extends StatelessWidget {
  const _PlanStatus({required this.state});

  final _PlanState state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          context.tr('medications.${state.name}_label'),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppSizes.iconSmall,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
