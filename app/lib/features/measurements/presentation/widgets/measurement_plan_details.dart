import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/widgets/layout/plan_detail_line.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_plan_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a measurement plan card opens: who added and last changed it, when
/// a reading counts as missed, and «إيقاف الخطة» in red for a manager.
List<Widget> measurementPlanDetails(
  BuildContext context, {
  required MeasurementPlan plan,
  required bool canManage,
}) => <Widget>[
  if (plan.createdByName case final String name)
    PlanDetailLine(context.tr('measurements.added_by', args: <String>[name])),
  if (plan.lastEditedByName case final String name
      when name != plan.createdByName)
    PlanDetailLine(
      context.tr('measurements.last_edited_by', args: <String>[name]),
    ),
  PlanDetailLine(
    '${context.tr('measurements.missed_after')} '
    '${arabicCount(context, ArabicCount.minutes, plan.version.missedAfterMinutes)}',
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
