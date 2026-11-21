import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_number.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_stepper.dart';
import 'package:flutter/material.dart';

/// After the dose's label: + , the number with its unit, − .
class MedicationDoseTrailing extends StatelessWidget {
  const MedicationDoseTrailing({
    super.key,
    required this.data,
    required this.units,
    required this.onChanged,
    required this.focusNode,
  });

  final ScheduleFormData data;
  final List<DoseUnit> units;
  final VoidCallback onChanged;

  /// The number's focus, which a tap on the row gives it.
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) => MedicationDoseStepper(
    data: data,
    onChanged: onChanged,
    middle: MedicationDoseNumber(
      data: data,
      units: units,
      onChanged: onChanged,
      focusNode: focusNode,
    ),
  );
}
