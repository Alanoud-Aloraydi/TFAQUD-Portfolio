import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/layout/plan_card_parts.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The «الخطة» tab's measurements: the active plans of [circleId], each
/// editable and stoppable when [canManage]. The plans and tasks read again
/// by themselves after a change saved anywhere.
class MeasurementPlanSection extends StatelessWidget {
  const MeasurementPlanSection({
    super.key,
    required this.circleId,
    required this.canManage,
    required this.header,
  });

  final String circleId;
  final bool canManage;
  final Widget header;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeasurementPlansCubit>().state;
    return ListView(
      padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
      children: [
        header,
        const SizedBox(height: AppSpacing.lg),
        if (state.status == MeasurementLoadStatus.loading &&
            state.plans.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (state.status == MeasurementLoadStatus.failure)
          TextButton(
            onPressed: () =>
                context.read<MeasurementPlansCubit>().load(circleId),
            child: Text(context.tr(state.errorKey ?? 'error.unknown')),
          )
        else if (state.plans.where((item) => item.stoppedAt == null).isEmpty)
          EmptyStateNote(
            context.tr('measurements.no_plans'),
            actionLabel: canManage ? context.tr('add.measurement') : null,
            onAction: canManage
                ? () => context.push(Routes.newMeasurement(circleId))
                : null,
          )
        else
          for (final plan in state.plans.where(
            (item) => item.stoppedAt == null,
          )) ...[
            MeasurementPlanCard(
              circleId: circleId,
              canManage: canManage,
              plan: plan,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

/// One active measurement plan: its kind, target, reading times and days,
/// a change waiting for later, and who added or last changed it.
class MeasurementPlanCard extends StatefulWidget {
  const MeasurementPlanCard({
    super.key,
    required this.circleId,
    required this.canManage,
    required this.plan,
  });

  final String circleId;
  final bool canManage;
  final MeasurementPlan plan;

  @override
  State<MeasurementPlanCard> createState() => _MeasurementPlanCardState();
}

class _MeasurementPlanCardState extends State<MeasurementPlanCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final version = plan.version;
    final today = PatientClockScope.of(context).today();
    final startsLater = version.effectiveFromOn.isAfter(today);
    final kind = plan.kind == MeasurementKind.glucose
        ? 'measurements.glucose'
        : 'measurements.bp';
    final target = plan.kind == MeasurementKind.glucose
        ? '${version.glucoseLow}–${version.glucoseHigh} '
              '${context.tr('measurements.glucose_unit')}'
        : context.tr(
            'measurements.bp_target',
            args: ['${version.systolicLimit}', '${version.diastolicLimit}'],
          );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppSemanticColors.surfaceContent,
                  child: Icon(
                    plan.kind == MeasurementKind.glucose
                        ? CupertinoIcons.drop
                        : CupertinoIcons.heart,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(kind),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      // With one glucose reading, its state under the name;
                      // with several, each state is beside its time below.
                      if (version.readingTimes.length == 1 &&
                          version.readingTimes.single.measurementState != null)
                        Text(
                          context.tr(
                            'measurements.condition.'
                            '${version.readingTimes.single.measurementState}',
                          ),
                        ),
                    ],
                  ),
                ),
                // Always editable, a change waiting for later too, with the
                // same pencil as a medicine and an appointment.
                if (widget.canManage)
                  PlanEditButton(
                    onPressed: () => context.push(
                      Routes.editMeasurement(widget.circleId, plan.id),
                    ),
                    tooltip: context.tr('measurements.edit_plan'),
                  ),
                CompactStatusBadge(
                  text: context.tr(
                    startsLater
                        ? 'measurements.starts_later'
                        : 'measurements.active',
                  ),
                  background: AppSemanticColors.selectedSurface,
                  foreground: AppSemanticColors.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppSemanticColors.surfaceContent,
                border: Border.all(color: AppSemanticColors.borderSubtle),
                borderRadius: BorderRadius.circular(AppRadius.field),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    for (final MeasurementTime reading in version.readingTimes)
                      Row(
                        children: [
                          Text(clockText(reading.time)),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              version.readingTimes.length > 1 &&
                                      reading.measurementState != null
                                  ? context.tr(
                                      'measurements.condition.'
                                      '${reading.measurementState}',
                                    )
                                  : context.tr('measurements.one_reading'),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        for (final day in const [6, 7, 1, 2, 3, 4, 5])
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 3),
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: version.weekdays.contains(day)
                                  ? AppSemanticColors.selectedSurface
                                  : AppSemanticColors.surfaceContent,
                              child: Text(
                                context.tr('medications.weekday_short.$day'),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppSemanticColors.surfaceContent,
                border: Border.all(color: AppSemanticColors.borderSubtle),
                borderRadius: BorderRadius.circular(AppRadius.field),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Text(context.tr('measurements.target')),
                    const Spacer(),
                    Text(target, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
            ),
            if (plan.pendingVersion != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  context.tr(
                    'measurements.pending_change',
                    args: [_dayText(plan.pendingVersion!.effectiveFromOn)],
                  ),
                ),
              ),
            PlanDetailsToggle(
              start: formatStartDate(context, _startsOn(plan), today: today),
              label: context.tr('measurements.details'),
              expanded: _expanded,
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded) ...[
              if (plan.createdByName case final name?) ...[
                Text(context.tr('measurements.added_by', args: [name])),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (plan.lastEditedByName case final name?
                  when name != plan.createdByName) ...[
                Text(context.tr('measurements.last_edited_by', args: [name])),
                const SizedBox(height: AppSpacing.xs),
              ],
              Text(
                context.tr(
                  'measurements.grace_value',
                  args: ['${version.graceMinutes}'],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // The stop in red text, as a medicine's and an appointment's;
              // the edit is the pencil at the top.
              if (widget.canManage)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => _stop(context),
                    child: Text(
                      context.tr('measurements.stop_plan'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _stop(BuildContext context) async {
    final confirmed = await showAppAlert<bool>(
      context,
      title: context.tr('measurements.stop_plan'),
      message: context.tr('measurements.stop_confirm'),
      actions: [
        AppAlertAction(label: context.tr('common.cancel'), value: false),
        AppAlertAction(
          label: context.tr('measurements.stop_plan'),
          value: true,
          destructive: true,
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    final String? errorKey = await context.read<MeasurementPlansCubit>().stop(
      widget.plan,
    );
    if (errorKey == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.tr(errorKey))));
  }
}

/// The first day of [plan]: its earliest version's, the one it started
/// with (an edit starts a later version).
DateTime _startsOn(MeasurementPlan plan) =>
    <MeasurementVersion>[plan.version, ...plan.history]
        .map((MeasurementVersion item) => item.effectiveFromOn)
        .reduce((DateTime a, DateTime b) => a.isBefore(b) ? a : b);

/// «9/11/2026» for [day], as the plan form's «يسري التعديل من» writes it.
String _dayText(DateTime day) => '${day.day}/${day.month}/${day.year}';
