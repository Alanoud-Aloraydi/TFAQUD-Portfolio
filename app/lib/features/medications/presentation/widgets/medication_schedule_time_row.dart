import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/medications/presentation/models/medication_schedule_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The time of day the dose is taken, opened as the app's time sheet.
class MedicationScheduleTimeRow extends StatelessWidget {
  const MedicationScheduleTimeRow({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final ScheduleFormData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InsetRow(
      label: context.tr('medications.time'),
      value: clockText(scheduleTimeCode(data.time)),
      onTap: () => _selectTime(context),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? selected = await showTafaqodTimeSheet(
      context,
      initialTime: data.time,
      title: context.tr('medications.select_time'),
    );
    if (selected == null) return;
    data.time = selected;
    onChanged();
  }
}

/// A time of day as the API writes it, «HH:mm».
String scheduleTimeCode(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';
