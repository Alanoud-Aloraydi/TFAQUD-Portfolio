import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_issue.dart';
import 'package:app/features/medications/presentation/widgets/medication_date_row.dart';
import 'package:app/features/medications/presentation/widgets/medication_duration_chips.dart';
import 'package:app/features/medications/presentation/widgets/medication_issue_note.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The treatment start and optional end in one grouped section.
class MedicationPeriodFields extends StatelessWidget {
  const MedicationPeriodFields({
    super.key,
    required this.data,
    required this.onChanged,
    this.issue,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;
  final MedicationFormIssue? issue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InsetGroup(
          header: context.tr('medications.treatment_period'),
          children: <Widget>[
            MedicationDurationChips(data: data, onChanged: onChanged),
            MedicationDateRow(
              label: context.tr('medications.starts'),
              value: data.startsOn,
              firstDate: data.effectiveFromOn == null
                  ? PatientClockScope.of(context).today()
                  : null,
              onChanged: (DateTime? value) {
                if (value == null) return;
                data.startsOn = value;
                onChanged();
              },
            ),
            if (data.endsOn != null)
              MedicationDateRow(
                label: context.tr('medications.ends'),
                value: data.endsOn,
                focusNode: data.periodFocus,
                onChanged: (DateTime? value) {
                  data.endsOn = value;
                  onChanged();
                },
              ),
          ],
        ),
        if (issue?.field == MedicationFormField.period)
          const MedicationIssueNote(messageKey: 'medications.invalid_period'),
      ],
    );
  }
}
