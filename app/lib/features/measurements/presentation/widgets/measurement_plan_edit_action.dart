import 'package:app/core/widgets/buttons/edit_action.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/care_item_routes.dart';

/// The pencil of a measurement plan card, to its form; none for someone who
/// cannot manage the plans.
EditAction? measurementPlanEditAction(
  BuildContext context, {
  required bool canManage,
  required String circleId,
  required String planId,
}) => canManage
    ? EditAction.pen(
        onPressed: () =>
            context.push(CareItemRoutes.editMeasurement(circleId, planId)),
        tooltip: context.tr('measurements.edit_plan'),
      )
    : null;
