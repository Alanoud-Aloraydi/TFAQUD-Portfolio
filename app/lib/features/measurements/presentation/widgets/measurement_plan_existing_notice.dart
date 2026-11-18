import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/care_item_routes.dart';

/// Said when the kind already has an active plan: it is edited, not added
/// again. An action row: a pencil, the words, and a chevron.
class MeasurementPlanExistingNotice extends StatelessWidget {
  const MeasurementPlanExistingNotice({
    super.key,
    required this.circleId,
    required this.planId,
  });

  final String circleId;
  final String planId;

  @override
  Widget build(BuildContext context) => InsetGroup(
    footer: context.tr('measurements.active_plan_exists'),
    children: [
      InsetRow(
        label: context.tr('measurements.edit_plan'),
        leading: const Icon(ActionIcons.pencil),
        showChevron: true,
        onTap: () {
          final router = GoRouter.of(context);
          final path = CareItemRoutes.editMeasurement(circleId, planId);
          context.pop();
          router.push(path);
        },
      ),
    ],
  );
}
