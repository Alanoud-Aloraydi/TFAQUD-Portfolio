import 'package:app/core/widgets/layout/inset_text_row.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_issue.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_trailing.dart';
import 'package:app/core/utils/arabic_digits.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// How much is taken: the number, typed in western digits whatever the
/// keyboard sends, with its unit and stepper beside it.
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
  Widget build(BuildContext context) {
    return InsetTextRow(
      label: context.tr('medications.dose_value'),
      hint: context.tr('medications.dose_hint'),
      controller: data.doseController,
      focusNode: data.doseFocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        const WesternDigitsFormatter(decimal: true),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      errorText: issue?.field == MedicationFormField.dose
          ? context.tr('medications.positive_number')
          : null,
      onChanged: (_) => onChanged(),
      trailing: MedicationDoseTrailing(
        data: data,
        units: units,
        onChanged: onChanged,
      ),
    );
  }
}
