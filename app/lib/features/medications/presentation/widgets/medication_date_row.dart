import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:flutter/material.dart';

class MedicationDateRow extends StatelessWidget {
  const MedicationDateRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.focusNode,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final DateTime? date = value;
    return InsetRow(
      label: label,
      value: date == null ? null : formatMedicationDate(context, date),
      focusNode: focusNode,
      onTap: () => _select(context),
      showChevron: true,
    );
  }

  Future<void> _select(BuildContext context) async {
    final DateTime now = PatientClockScope.of(context).today();
    final DateTime? selected = await showTafaqodDateSheet(
      context,
      title: label,
      initialDate:
          value != null && firstDate != null && value!.isBefore(firstDate!)
          ? firstDate!
          : value ?? now,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (selected != null) onChanged(selected);
  }
}
