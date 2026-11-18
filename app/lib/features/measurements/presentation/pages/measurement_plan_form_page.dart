import 'package:app/features/measurements/presentation/pages/measurement_plan_form_state.dart';
import 'package:flutter/material.dart';

/// «جدولة قياس» (new, [planId] null) or «تعديل جدولة القياس» of [planId].
///
/// An edit starts from the plan's latest version (a change waiting for
/// later, when there is one) and is saved against that version's number,
/// so a change made elsewhere meanwhile is refused, not overwritten.
class MeasurementPlanFormPage extends StatefulWidget {
  const MeasurementPlanFormPage({
    super.key,
    required this.circleId,
    this.planId,
  });

  final String circleId;
  final String? planId;

  @override
  State<MeasurementPlanFormPage> createState() => MeasurementPlanFormState();
}
