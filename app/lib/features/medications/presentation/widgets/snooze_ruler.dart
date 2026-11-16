import 'package:app/core/l10n/duration_text.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/medications/presentation/widgets/ruler_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The ruler of the snooze sheet: 5 minutes a mark, a long mark every half
/// hour, and the hours written under them.
class SnoozeRuler extends StatelessWidget {
  const SnoozeRuler({
    super.key,
    required this.maxMinutes,
    required this.minutes,
    required this.onChanged,
  });

  final int maxMinutes;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return RulerPicker(
      min: snoozeStepMinutes,
      max: maxMinutes,
      step: snoozeStepMinutes,
      value: minutes,
      onChanged: onChanged,
      semanticLabel: context.tr('reminders.snooze_title'),
      valueLabel: (int value) => afterDuration(context, value),
      isMajor: (int value) => value % 30 == 0,
      tickLabel: (int value) => value % 60 == 0
          ? context.tr(
              'reminders.snooze_hours_tick',
              args: <String>['${value ~/ 60}'],
            )
          : '',
    );
  }
}
