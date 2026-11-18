import 'package:app/core/widgets/forms/field_with_error.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/models/medication_form_issue.dart';
import 'package:app/features/medications/presentation/widgets/medication_date_row.dart';
import 'package:app/features/medications/presentation/widgets/medication_duration_chips.dart';
import 'package:app/features/medications/presentation/widgets/medication_issue_note.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The treatment start and optional end in one grouped section. A start in
/// the past ([startError]) is said under the start.
class MedicationPeriodFields extends StatelessWidget {
  const MedicationPeriodFields({
    super.key,
    required this.data,
    required this.onChanged,
    this.issue,
    this.startError,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;
  final MedicationFormIssue? issue;

  /// The translation key of the start's refusal, or null.
  final String? startError;

  @override
  Widget build(BuildContext context) {
    final String? start = startError == null ? null : context.tr(startError!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FieldWithError.reveal(
          error: start,
          child: InsetGroup(
            header: context.tr('medications.treatment_period'),
            children: <Widget>[
              MedicationDurationChips(data: data, onChanged: onChanged),
              MedicationDateRow(
                label: context.tr('medications.starts'),
                value: data.startsOn,
                errorText: start,
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
        ),
        if (issue?.field == MedicationFormField.period)
          const MedicationIssueNote(messageKey: 'medications.invalid_period'),
      ],
    );
  }
}
