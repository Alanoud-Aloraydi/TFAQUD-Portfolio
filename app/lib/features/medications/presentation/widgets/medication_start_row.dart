import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/presentation/models/medication_form_data.dart';
import 'package:app/features/medications/presentation/widgets/medication_date_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «يبدأ» of a treatment: its first day, from the patient's today for a new
/// plan, and the start's refusal ([error]) under it.
class MedicationStartRow extends StatelessWidget {
  const MedicationStartRow({
    super.key,
    required this.data,
    required this.onChanged,
    this.error,
  });

  final MedicationFormData data;
  final VoidCallback onChanged;

  /// The start's refusal, translated, or null.
  final String? error;

  @override
  Widget build(BuildContext context) => MedicationDateRow(
    label: context.tr('medications.starts'),
    value: data.startsOn,
    errorText: error,
    firstDate: data.effectiveFromOn == null
        ? PatientClockScope.of(context).today()
        : null,
    onChanged: (DateTime? value) {
      if (value == null) return;
      data.startsOn = value;
      onChanged();
    },
  );
}
