import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/medications/presentation/widgets/medication_history_section.dart';
import 'package:flutter/material.dart';

class RecordPage extends StatelessWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectedCircleBuilder(
      builder: (context, circleId) =>
          MedicationHistorySection(circleId: circleId),
    );
  }
}
