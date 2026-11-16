import 'package:app/core/widgets/forms/weekday_selector.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:flutter/material.dart';

/// The days of the week the dose is taken on.
class MedicationWeekdaysField extends StatelessWidget {
  const MedicationWeekdaysField({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final ScheduleFormData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => WeekdaySelector(
    selected: data.weekdays,
    onChanged: (Set<int> days) {
      data.weekdays
        ..clear()
        ..addAll(days);
      onChanged();
    },
  );
}
