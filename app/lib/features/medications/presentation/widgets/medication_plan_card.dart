import 'package:app/core/navigation/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_occurrences_cubit.dart';
import 'package:app/features/medications/presentation/cubit/medications_cubit.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Displays the medication plan card UI.
class MedicationPlanCard extends StatefulWidget {
  const MedicationPlanCard({
    super.key,
    required this.circleId,
    required this.plan,
    required this.canManage,
  });

  final String circleId;
  final MedicationPlan plan;
  final bool canManage;

  @override
  State<MedicationPlanCard> createState() => _MedicationPlanCardState();
}

class _MedicationPlanCardState extends State<MedicationPlanCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final version = plan.version;
    final strength =
        '${formatMedicationNumber(version.strengthValue)} '
        '${context.tr('medications.strength_display.${version.strengthUnit.name}')}';
    final today = riyadhToday();
    final status = plan.isPreviousOn(today)
        ? _PlanState.previous
        : plan.isScheduledOn(today)
        ? _PlanState.scheduled
        : _PlanState.current;
    final canManage = widget.canManage;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(
          AppRadius.m,
          side: const BorderSide(color: AppSemanticColors.borderSubtle),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MedicationPhotoBuilder(
              circleId: widget.circleId,
              planId: plan.id,
              builder: (context, bytes) => bytes == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: MedicationPhotoImage(bytes: bytes, height: 140),
                    ),
            ),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSizes.touch),
                child: Row(
                  children: [
                    MedicationPhotoBuilder(
                      circleId: widget.circleId,
                      planId: plan.id,
                      builder: (context, bytes) => bytes != null
                          ? const SizedBox.shrink()
                          : Container(
                              width: AppSizes.touch,
                              height: AppSizes.touch,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppSemanticColors.surfaceContent,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.field,
                                ),
                              ),
                              child: const Icon(
                                TafaqodPhosphorIcons.pill,
                                color: AppSemanticColors.textSupporting,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: AppSpacing.xs,
                            children: [
                              Text(
                                version.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                strength,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          Text(
                            context.tr(
                              'medications.form.${version.dosageForm.name}',
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (canManage &&
                        status == _PlanState.current &&
                        plan.pendingVersion == null)
                      IconButton(
                        onPressed: () => _edit(context),
                        icon: const Icon(AppIcons.pencil),
                        tooltip: context.tr('medications.edit_title'),
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
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppSemanticColors.surfaceContent,
                border: Border.all(color: AppSemanticColors.borderSubtle),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'medications.pending_revision',
                          args: [
                            formatMedicationDate(
                              context,
                              pending.effectiveFromOn,
                            ),
                          ],
                        ),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _scheduleSummary(context, version.schedules),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(decoration: TextDecoration.lineThrough),
                      ),
                      Text(
                        _scheduleSummary(context, pending.schedules),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.tr('medications.effective_hint'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Row(
              children: [
                const Icon(CupertinoIcons.calendar, size: AppSizes.iconSmall),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _period(context, version.startsOn, version.endsOn),
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
              _DetailValue(
                label: context.tr('medications.missed_after'),
                value: context.tr(
                  'medications.missed_option.${version.missedAfterMinutes}',
                ),
              ),
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
                  if (canManage &&
                      status == _PlanState.current &&
                      plan.pendingVersion == null)
                    TextButton(
                      onPressed: () => _edit(context),
                      child: Text(context.tr('medications.edit_title')),
                    ),
                  if (canManage && status != _PlanState.previous)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppSemanticColors.statusError,
                      ),
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

  String _scheduleSummary(
    BuildContext context,
    List<MedicationSchedule> schedules,
  ) => schedules
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

/// Renders the detail value element of medication plan card.
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

/// Renders the schedule line element of medication plan card.
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
    final days = Row(
      mainAxisSize: MainAxisSize.min,
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
              width: 16,
              height: 16,
              child: Center(
                child: Text(
                  context.tr('medications.weekday_short.$day'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ),
          ),
          if (day != 5) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 290
            ? Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      time,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(dose)),
                  days,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(time, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(dose)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  days,
                ],
              ),
      ),
    );
  }
}

/// Defines the supported plan state values.
enum _PlanState { current, scheduled, previous }

/// Renders the plan status element of medication plan card.
class _PlanStatus extends StatelessWidget {
  const _PlanStatus({required this.state});

  final _PlanState state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: state == _PlanState.current
            ? AppSemanticColors.selectedSurface
            : AppSemanticColors.surfaceContent,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state == _PlanState.current) ...[
              const Icon(TafaqodPhosphorIcons.check, size: 12),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              context.tr('medications.${state.name}_label'),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
