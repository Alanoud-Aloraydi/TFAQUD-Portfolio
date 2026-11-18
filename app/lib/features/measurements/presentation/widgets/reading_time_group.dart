import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «وقت القياس الفعلي» of the reading sheet: the [time] shown, and the
/// time sheet to pick another.
class ReadingTimeGroup extends StatelessWidget {
  const ReadingTimeGroup({
    super.key,
    required this.time,
    required this.onPicked,
  });

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onPicked;

  @override
  Widget build(BuildContext context) => InsetGroup(
    children: [
      InsetRow(
        label: context.tr('measurements.actual_time'),
        value: timeOfDayText(time),
        onTap: () async {
          final selected = await showTafaqodTimeSheet(
            context,
            title: context.tr('measurements.actual_time'),
            initialTime: time,
          );
          if (selected != null && context.mounted) onPicked(selected);
        },
      ),
    ],
  );
}
