import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/features/medications/presentation/cubit/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_history.dart';
import 'package:app/features/medications/presentation/widgets/stepper_half_button.dart';
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

/// The dose stepper: + in a round lavender button, then [middle] (the
/// number and its unit), then − in a light one, at the end of a row. Null
/// [onDecrement] or [onIncrement] turns that button off, for example − at
/// the smallest dose.
class StepperControl extends StatelessWidget {
  const StepperControl({
    super.key,
    required this.onDecrement,
    required this.onIncrement,
    required this.decrementLabel,
    required this.incrementLabel,
    required this.middle,
  });

  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  /// What VoiceOver reads for each button, for example «إنقاص الجرعة».
  final String decrementLabel;
  final String incrementLabel;
  final Widget middle;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      StepperHalfButton(
        icon: ActionIcons.plus,
        label: incrementLabel,
        onPressed: onIncrement,
        strong: true,
      ),
      middle,
      StepperHalfButton(
        icon: ActionIcons.minus,
        label: decrementLabel,
        onPressed: onDecrement,
      ),
    ],
  );
}
