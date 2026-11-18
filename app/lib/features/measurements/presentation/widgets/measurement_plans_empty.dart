import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/navigation/care_item_routes.dart';

/// «ما في قياسات»: nothing planned yet, with «إضافة قياس» for someone who
/// can manage the plans.
class MeasurementPlansEmpty extends StatelessWidget {
  const MeasurementPlansEmpty({
    super.key,
    required this.circleId,
    required this.canManage,
  });

  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) => EmptyStateNote.section(
    context.tr('measurements.no_plans'),
    actionLabel: canManage ? context.tr('add.measurement') : null,
    onAction: canManage
        ? () => context.push(CareItemRoutes.newMeasurement(circleId))
        : null,
  );
}
