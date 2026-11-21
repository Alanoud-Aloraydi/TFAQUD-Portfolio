import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_step.dart';
import 'package:app/features/medications/presentation/widgets/stepper_control.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The two buttons that count the dose up and down, by half a tablet or by
/// one of whatever else it is, around [middle] (the number and its unit).
/// Each button is off at its end of the range.
class MedicationDoseStepper extends StatelessWidget {
  const MedicationDoseStepper({
    super.key,
    required this.data,
    required this.onChanged,
    required this.middle,
  });

  final ScheduleFormData data;
  final VoidCallback onChanged;
  final Widget middle;

  @override
  Widget build(BuildContext context) {
    final double step = doseStep(data.doseUnit);
    final double? dose = typedDose(data.doseController.text);
    return StepperControl(
      decrementLabel: context.tr('medications.dose_less'),
      incrementLabel: context.tr('medications.dose_more'),
      onDecrement: dose != null && dose > step ? () => _step(-1, step) : null,
      onIncrement: dose == null || dose < maxDose ? () => _step(1, step) : null,
      middle: middle,
    );
  }

  void _step(int direction, double step) {
    data.doseController.text = formatMedicationNumber(
      steppedDose(typedDose(data.doseController.text), direction, step),
    );
    onChanged();
  }
}
