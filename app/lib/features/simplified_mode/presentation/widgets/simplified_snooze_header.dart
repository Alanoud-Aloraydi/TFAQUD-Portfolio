import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/widgets/pickers/ruler_picker.dart';
import 'package:app/features/medications/domain/entities/snooze_limit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «متى أذكّرك؟», then, as the detailed sheet, how long («بعد 15 دقيقة»)
/// over the clock time it means, in this mode's largest type.
class SimplifiedSnoozeHeader extends StatelessWidget {
  const SimplifiedSnoozeHeader({
    super.key,
    required this.minutes,
    required this.clock,
  });

  /// What is chosen now; null when there is no room to put the task off.
  final int? minutes;

  /// «الساعة 6:27 مساءً», the time [minutes] means.
  final String clock;

  @override
  Widget build(BuildContext context) {
    const Color ink = SimplifiedColors.surface;
    return Column(
      children: <Widget>[
        Text(
          context.tr('simplified_mode.when_remind'),
          textAlign: TextAlign.center,
          style: SimplifiedStyle.head(28, color: ink),
        ),
        const SizedBox(height: 28),
        if (minutes case final int chosen) ...<Widget>[
          Text(
            afterDuration(context, chosen),
            textAlign: TextAlign.center,
            style: SimplifiedStyle.head(SimplifiedStyle.hero, color: ink),
          ),
          Text(
            clock,
            textAlign: TextAlign.center,
            style: SimplifiedStyle.text(
              SimplifiedStyle.title,
              color: SimplifiedColors.onDarkMuted,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

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
    mark: SimplifiedColors.accent,
    major: SimplifiedColors.surface,
    minor: SimplifiedColors.onDarkMuted,
    label: SimplifiedColors.onDarkMuted,
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
