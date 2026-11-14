import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/widgets/display/weekday_strip.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/domain/normal_range.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_ranges_cubit.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What a measurement plan card opens, in groups: «الجدول» (each time in
/// bold with its meal state, and the days), «المعدل الطبيعي» of its
/// readings, «عن القياس» (when a reading counts as missed), «الأشخاص» (who
/// added and last changed it, with their pictures), and «إيقاف الخطة» in
/// red for a manager.
List<Widget> measurementPlanDetails(
  BuildContext context, {
  required String circleId,
  required MeasurementPlan plan,
  required bool canManage,
}) {
  final MeasurementVersion version = plan.version;
  return <Widget>[
    PlanFactGroup(
      title: context.tr('plan_details.schedule'),
      children: <Widget>[
        for (final MeasurementTime reading in version.readingTimes)
          PlanFact(
            icon: AppIcons.clock,
            value: clockText(reading.time),
            trailing: reading.measurementState == null
                ? null
                : StatusBadge(
                    text: context.tr(
                      'measurements.condition.${reading.measurementState}',
                    ),
                    tone: StatusTone.neutral,
                  ),
          ),
        PlanFact(
          icon: AppIcons.calendar,
          label: context.tr('measurements.days'),
          below: WeekdayStrip(days: version.weekdays),
        ),
      ],
    ),
    _PlanRanges(plan: plan),
    PlanFactGroup(
      title: context.tr('plan_details.about_measurement'),
      children: <Widget>[
        PlanFact(
          icon: AppIcons.hourglass,
          label: context.tr('measurements.missed_after'),
          value: arabicCount(
            context,
            ArabicCount.minutes,
            version.missedAfterMinutes,
          ),
        ),
      ],
    ),
    if (plan.createdByName != null || plan.lastEditedByName != null)
      PlanFactGroup(
        title: context.tr('plan_details.people'),
        children: <Widget>[
          if (plan.createdByName case final String name)
            PlanPersonFact(
              label: context.tr('medications.added_by'),
              name: name,
              circleId: circleId,
              accountId: plan.createdByAccountId,
              avatarCode: plan.createdByAvatarCode,
            ),
          if (plan.lastEditedByName case final String name
              when name != plan.createdByName)
            PlanPersonFact(
              label: context.tr('medications.last_edited_by'),
              name: name,
              circleId: circleId,
              accountId: plan.lastEditedByAccountId,
              avatarCode: plan.lastEditedByAvatarCode,
            ),
        ],
      ),
    if (canManage)
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppItemCard.touch),
            foregroundColor: AppSemanticColors.statusError,
          ),
          onPressed: () => stopMeasurementPlan(context, plan),
          child: Text(context.tr('measurements.stop_plan')),
        ),
      ),
  ];
}

/// «المعدل الطبيعي» of a plan's readings, from the section's
/// [MeasurementRangesCubit]: one line per range (glucose: per meal state
/// its times use). Nothing while the ranges load or fail; the reading
/// sheet shows them too.
class _PlanRanges extends StatelessWidget {
  const _PlanRanges({required this.plan});

  final MeasurementPlan plan;

  @override
  Widget build(BuildContext context) {
    final NormalRanges? ranges = context
        .watch<MeasurementRangesCubit>()
        .state
        .ranges;
    if (ranges == null) return const SizedBox.shrink();
    final MeasurementKind kind = plan.kind;
    final List<NormalRange> shown = kind == MeasurementKind.bp
        ? <NormalRange>[?ranges.of(kind)]
        : <NormalRange>[
            for (final String group in <String>{
              for (final MeasurementTime item in plan.version.readingTimes)
                normalRangeState(item.measurementState),
            })
              ?ranges.of(kind, group),
          ];
    return PlanFactGroup(
      title: context.tr('measurements.normal_range'),
      children: <Widget>[
        for (final NormalRange range in shown)
          PlanFact(
            icon: kind == MeasurementKind.bp
                ? AppIcons.heartbeat
                : AppIcons.drop,
            label: normalRangeCaption(
              context,
              kind,
              range.profile,
              range.state,
            ),
            value:
                '${normalBandText(context, kind, range.normal)} '
                '${context.tr(kind == MeasurementKind.bp ? 'measurements.bp_unit' : 'measurements.glucose_unit')}',
          ),
      ],
    );
  }
}
