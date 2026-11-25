import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:app/features/measurements/presentation/cubit/plan_schedule_draft.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «القراءة 2» when there are several readings, «الوقت» for a single one.
String planReadingLabel(BuildContext context, int count, int index) =>
    count == 1
    ? context.tr('measurements.time')
    : context.tr('measurements.reading_number', args: ['${index + 1}']);

/// The time of reading [index] of a plan, and «حذف» for all but a single
/// reading. [onEdit] runs a change and clears the error shown.
class PlanReadingTimeRow extends StatelessWidget {
  const PlanReadingTimeRow({
    super.key,
    required this.readings,
    required this.index,
    required this.repeated,
    required this.onEdit,
  });

  final List<PlanReadingDraft> readings;
  final int index;

  /// The form was refused for two same times: said under each of them.
  final bool repeated;
  final void Function(VoidCallback change) onEdit;

  @override
  Widget build(BuildContext context) {
    final PlanReadingDraft reading = readings[index];
    final String label = planReadingLabel(context, readings.length, index);
    final bool same =
        repeated &&
        readings.where((item) => item.time == reading.time).length > 1;
    return InsetRow(
      label: label,
      value: timeOfDayText(reading.time),
      errorText: same ? context.tr('measurements.times_repeat') : null,
      trailing: readings.length == 1
          ? null
          : IconButton(
              tooltip: context.tr(
                'measurements.remove_reading',
                args: ['${index + 1}'],
              ),
              icon: const Icon(ActionIcons.trash),
              onPressed: () => onEdit(() => readings.removeAt(index)),
            ),
      onTap: () async {
        final selected = await showTafaqodTimeSheet(
          context,
          title: label,
          initialTime: reading.time,
        );
        if (selected != null && context.mounted) {
          onEdit(() => reading.time = selected);
        }
      },
    );
  }
}
