import 'package:app/core/l10n/duration_text.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/medications/presentation/widgets/ruler_look.dart';
import 'package:app/features/medications/presentation/widgets/ruler_picker.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The detailed mode's snooze ruler, larger and in the dark screen's
/// colours: 5 minutes a mark, a long mark every half hour, the hours under
/// them.
class SimplifiedSnoozeRuler extends StatelessWidget {
  const SimplifiedSnoozeRuler({
    super.key,
    required this.maxMinutes,
    required this.minutes,
    required this.onChanged,
  });

  final int maxMinutes;
  final int minutes;
  final ValueChanged<int> onChanged;

  static const RulerLook _look = RulerLook(
    scale: 1.6,
    mark: SimplifiedStyle.accent,
    major: SimplifiedStyle.surface,
    minor: SimplifiedStyle.onDarkMuted,
    label: SimplifiedStyle.onDarkMuted,
  );

  @override
  Widget build(BuildContext context) => RulerPicker(
    min: snoozeStepMinutes,
    max: maxMinutes,
    step: snoozeStepMinutes,
    value: minutes,
    onChanged: onChanged,
    semanticLabel: context.tr('simplified_mode.when_remind'),
    valueLabel: (int value) => afterDuration(context, value),
    isMajor: (int value) => value % 30 == 0,
    tickLabel: (int value) => value % 60 == 0
        ? context.tr(
            'reminders.snooze_hours_tick',
            args: <String>['${value ~/ 60}'],
          )
        : '',
    look: _look,
  );
}
