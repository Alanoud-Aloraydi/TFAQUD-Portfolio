import 'package:app/core/l10n/calendar_texts.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/date_picker_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «يبدأ» (a new plan) or «يسري من» (an edit): the first day, chosen on the
/// patient's calendar, never before the patient's today.
class PlanStartRow extends StatelessWidget {
  const PlanStartRow({
    super.key,
    required this.start,
    required this.isNew,
    required this.onPicked,
  });

  final DateTime start;
  final bool isNew;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    final String label = context.tr(
      isNew ? 'measurements.starts' : 'measurements.effective_start',
    );
    return InsetRow(
      label: label,
      value: calendarDate(context, start),
      onTap: () async {
        final earliest = PatientClockScope.of(context).today();
        final selected = await showTafaqodDateSheet(
          context,
          title: label,
          initialDate: start.isBefore(earliest) ? earliest : start,
          firstDate: earliest,
          lastDate: earliest.add(const Duration(days: 3650)),
        );
        if (selected != null && context.mounted) onPicked(selected);
      },
    );
  }
}
