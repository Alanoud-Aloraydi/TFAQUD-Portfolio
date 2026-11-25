import 'package:app/core/widgets/forms/tap_to_focus.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/inset_text_line.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_number.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_stepper.dart';
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
