import 'package:app/core/l10n/calendar_texts.dart';
import 'package:app/core/widgets/layout/plan_info_box.dart';
import 'package:app/features/measurements/domain/measurement_version.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «يسري التعديل من 9 نوفمبر 2026» (or Hijri, as chosen in «حسابي»): the
/// change of a plan that waits for its day.
class MeasurementPlanPendingNote extends StatelessWidget {
  const MeasurementPlanPendingNote({super.key, required this.pending});

  final MeasurementVersion pending;

  @override
  Widget build(BuildContext context) => PlanInfoBox(
    emphasis: true,
    child: Text(
      context.tr(
        'measurements.pending_change',
        args: <String>[calendarDate(context, pending.effectiveFromOn)],
      ),
    ),
  );
}
