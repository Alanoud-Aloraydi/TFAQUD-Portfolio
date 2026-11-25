import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/forms/tap_to_focus.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/inset_text_line.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_history.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_number.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// How much is taken: its label, then + , the number with its unit, − .
/// A tap anywhere on the row puts the cursor in the number.
class MedicationDoseRow extends StatelessWidget {
  const MedicationDoseRow({
    super.key,
    required this.data,
    required this.units,
    required this.onChanged,
    this.issue,
  });

  final ScheduleFormData data;
  final List<DoseUnit> units;
  final VoidCallback onChanged;
  final MedicationFormIssue? issue;

  @override
  Widget build(BuildContext context) => TapToFocus(
    focusNode: data.doseFocus,
    builder: (FocusNode node) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InsetTextLine(
          label: context.tr('medications.dose_value'),
          multiline: false,
          field: const SizedBox.shrink(),
          trailing: MedicationDoseTrailing(
            data: data,
            units: units,
            onChanged: onChanged,
            focusNode: node,
          ),
        ),
        if (issue?.field == MedicationFormField.dose)
          InsetRowError(context.tr('medications.positive_number')),
      ],
    ),
  );
}

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

/// One round button of the dose stepper: a 34 point circle drawn inside a
/// 44 point tap. [strong] is + in the app's lavender; − is the light one.
/// Null [onPressed] greys it out, at its end of the range.
class StepperHalfButton extends StatelessWidget {
  const StepperHalfButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.strong = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool strong;

  static const double _circle = 34;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onPressed,
    padding: EdgeInsets.zero,
    constraints: BoxConstraints.tight(const Size.square(AppSizes.touch)),
    icon: Container(
      width: _circle,
      height: _circle,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onPressed == null
            ? AppSemanticColors.selectedSurface
            : strong
            ? AppSemanticColors.actionPrimary
            : AppSemanticColors.selectedSurface,
      ),
      child: Icon(
        icon,
        size: AppSizes.iconSmall,
        color: onPressed == null
            ? AppSemanticColors.borderControlBase
            : strong
            ? AppSemanticColors.onActionPrimary
            : AppSemanticColors.actionStrong,
      ),
    ),
  );
}
