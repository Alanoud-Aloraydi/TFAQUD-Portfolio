import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/pickers/time_picker_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «وقت أخذ الجرعة» of «سجّل جرعة الآن»: the [time] shown, and the time
/// sheet to pick another.
class ExtraDoseTimeGroup extends StatelessWidget {
  const ExtraDoseTimeGroup({
    super.key,
    required this.time,
    required this.onPicked,
  });

  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onPicked;

  @override
  Widget build(BuildContext context) => InsetGroup(
    children: <Widget>[
      InsetRow(
        label: context.tr('medications.dose_now_time'),
        value: timeOfDayText(time),
        onTap: () async {
          final TimeOfDay? selected = await showTafaqodTimeSheet(
            context,
            title: context.tr('medications.dose_now_time'),
            initialTime: time,
          );
          if (selected != null && context.mounted) onPicked(selected);
        },
      ),
    ],
  );
}
