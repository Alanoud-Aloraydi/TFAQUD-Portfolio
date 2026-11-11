import 'package:app/core/widgets/layout/plan_info_box.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «الهدف»: the range a glucose plan aims for, or the limits of a blood
/// pressure plan.
class MeasurementPlanTargetBox extends StatelessWidget {
  const MeasurementPlanTargetBox({
    super.key,
    required this.kind,
    required this.version,
  });

  final MeasurementKind kind;
  final MeasurementVersion version;

  @override
  Widget build(BuildContext context) {
    final String target = kind == MeasurementKind.glucose
        ? '${version.glucoseLow}–${version.glucoseHigh} '
              '${context.tr('measurements.glucose_unit')}'
        : context.tr(
            'measurements.bp_target',
            args: <String>[
              '${version.systolicLimit}',
              '${version.diastolicLimit}',
            ],
          );
    return PlanInfoBox(
      child: Row(
        children: <Widget>[
          Text(context.tr('measurements.target')),
          const Spacer(),
          Text(target, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}
