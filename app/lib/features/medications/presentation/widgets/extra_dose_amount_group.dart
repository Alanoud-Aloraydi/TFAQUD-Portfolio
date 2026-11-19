import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/models/medication_form_field.dart';
import 'package:app/features/medications/presentation/models/medication_form_issue.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_dose_row.dart';
import 'package:flutter/material.dart';

/// «كمية الجرعة» of «سجّل جرعة الآن», in the units [plan]'s form is taken
/// in.
class ExtraDoseAmountGroup extends StatelessWidget {
  const ExtraDoseAmountGroup({
    super.key,
    required this.plan,
    required this.dose,
    required this.onChanged,
    required this.showError,
  });

  final MedicationPlan plan;
  final ScheduleFormData dose;
  final VoidCallback onChanged;

  /// Save was tapped while the dose is not a number above zero.
  final bool showError;

  @override
  Widget build(BuildContext context) => InsetGroup(
    children: <Widget>[
      MedicationDoseRow(
        data: dose,
        units: plan.version.dosageForm.doseUnits,
        onChanged: onChanged,
        issue: showError
            ? const MedicationFormIssue(MedicationFormField.dose)
            : null,
      ),
    ],
  );
}
