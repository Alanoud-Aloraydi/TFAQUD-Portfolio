import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/medications/presentation/cubit/medication_schedule_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// «جدول 1» over the row, with the button that removes it. The button is
/// absent while the medicine has one schedule left.
class MedicationScheduleHeader extends StatelessWidget {
  const MedicationScheduleHeader({
    super.key,
    required this.index,
    this.onRemove,
  });

  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? remove = onRemove;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.sm,
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr(
                'medications.schedule_number',
                args: [(index + 1).toString()],
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (remove != null)
            IconButton(
              tooltip: context.tr('medications.remove_schedule'),
              onPressed: remove,
              color: AppSemanticColors.statusError,
              icon: const Icon(CupertinoIcons.delete),
            ),
        ],
      ),
    );
  }
}

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
