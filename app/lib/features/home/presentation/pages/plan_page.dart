import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/medications/presentation/widgets/medication_plans_section.dart';
import 'package:flutter/material.dart';

class PlanPage extends StatelessWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectedCircleBuilder(
      builder: (context, circleId) =>
          MedicationPlansSection(circleId: circleId),
    );
  }
}
