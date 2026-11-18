import 'package:app/core/widgets/layout/plan_info_box.dart';
import 'package:app/features/measurements/domain/measurement_version.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «يسري التعديل من 9/11/2026»: the change of a plan that waits for its day.
class MeasurementPlanPendingNote extends StatelessWidget {
  const MeasurementPlanPendingNote({super.key, required this.pending});

  final MeasurementVersion pending;

  @override
  Widget build(BuildContext context) => PlanInfoBox(
    emphasis: true,
    child: Text(
      context.tr(
        'measurements.pending_change',
        args: <String>[_dayText(pending.effectiveFromOn)],
      ),
    ),
  );

  /// «9/11/2026», as the plan form's «يسري التعديل من» writes it.
  static String _dayText(DateTime day) => '${day.day}/${day.month}/${day.year}';
}
