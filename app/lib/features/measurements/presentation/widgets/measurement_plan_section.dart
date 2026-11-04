import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_plans_cubit.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_states.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Displays the measurement plan section UI.
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
          Center(child: Text(context.tr('measurements.no_plans')))
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

/// Displays the measurement plan card UI.
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
    final today = riyadhToday();
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
                      if (version.glucoseContext != null)
                        Text(
                          context.tr(
                            'measurements.context.${version.glucoseContext}',
                          ),
                        ),
                    ],
                  ),
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
                    Row(
                      children: [
                        Text(_formatTime(version.time)),
                        const Spacer(),
                        Text(context.tr('measurements.one_reading')),
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
                    args: [
                      measurementDate(plan.pendingVersion!.effectiveFromOn),
                    ],
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? CupertinoIcons.chevron_up
                    : CupertinoIcons.chevron_down,
              ),
              label: Text(context.tr('medications.details')),
            ),
            if (_expanded) ...[
              Text(
                context.tr(
                  'measurements.grace_value',
                  args: ['${version.graceMinutes}'],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (widget.canManage)
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: plan.pendingVersion != null
                          ? null
                          : () async {
                              final saved = await context.push<bool>(
                                Routes.editMeasurement(
                                  widget.circleId,
                                  plan.id,
                                ),
                              );
                              if (saved == true && context.mounted) {
                                context.read<MeasurementPlansCubit>().load(
                                  widget.circleId,
                                );
                                context.read<MeasurementTasksCubit>().reload();
                              }
                            },
                      icon: const Icon(AppIcons.pencil),
                      label: Text(context.tr('measurements.edit_plan')),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TextButton(
                      onPressed: () => _stop(context),
                      child: Text(
                        context.tr('measurements.stop_plan'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
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
    final stopped = await context.read<MeasurementPlansCubit>().stop(
      widget.plan,
    );
    if (stopped && context.mounted) {
      context.read<MeasurementTasksCubit>().reload();
    }
  }

  String _formatTime(String value) {
    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    return '${hour % 12 == 0 ? 12 : hour % 12}:$minute '
        '${context.tr(hour < 12 ? 'common.am' : 'common.pm')}';
  }
}
