import 'package:app/features/home/presentation/widgets/selected_circle_builder.dart';
import 'package:app/features/medications/presentation/widgets/today_medication_section.dart';
import 'package:flutter/material.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SelectedCircleBuilder(
      builder: (context, circleId) => const TodayMedicationSection(),
    );
  }
}
