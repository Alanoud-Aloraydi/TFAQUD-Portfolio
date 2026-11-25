import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/widgets/pickers/ruler_picker.dart';
import 'package:app/features/medications/domain/entities/snooze_limit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «متى أذكّرك؟» as the detailed mode asks it, larger and straight on the
/// dark ground: how long, the clock time it means, the ruler with its «−»
/// and «+», and how far the reminder can go.
class SimplifiedSnoozeBody extends StatelessWidget {
  const SimplifiedSnoozeBody({
    super.key,
    required this.minutes,
    required this.maxMinutes,
    required this.clock,
    required this.onChanged,
  });

  /// What is chosen now, and the most that can be; zero when the next dose
  /// of the same medicine leaves no room.
  final int minutes;
  final int maxMinutes;

  /// «الساعة 6:27 مساءً», the time [minutes] means.
  final String clock;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    // The ruler takes the whole width, as in the detailed sheet.
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      SimplifiedSnoozeHeader(
        minutes: maxMinutes > 0 ? minutes : null,
        clock: clock,
      ),
      // One mark alone is nothing to slide along.
      if (maxMinutes > snoozeStepMinutes) ...<Widget>[
        SimplifiedSnoozeRuler(
          maxMinutes: maxMinutes,
          minutes: minutes,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        SimplifiedSnoozeSteps(
          maxMinutes: maxMinutes,
          minutes: minutes,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
      SimplifiedSnoozeNote(maxMinutes: maxMinutes),
    ],
  );
}

/// How far the reminder can be put off, in the detailed sheet's own
/// words: the app's twelve hours, the shorter room before the medicine's
/// next dose, or none at all.
class SimplifiedSnoozeNote extends StatelessWidget {
  const SimplifiedSnoozeNote({super.key, required this.maxMinutes});

  final int maxMinutes;

  @override
  Widget build(BuildContext context) => Text(
    maxMinutes <= 0
        ? context.tr('reminders.snooze_none')
        : context.tr(
            maxMinutes < maxSnooze.inMinutes
                ? 'reminders.snooze_limit_next'
                : 'reminders.snooze_limit',
            args: <String>[durationText(context, maxMinutes)],
          ),
    textAlign: TextAlign.center,
    style: SimplifiedStyle.text(
      SimplifiedStyle.body,
      color: SimplifiedColors.onDarkMuted,
    ),
  );
}

/// «−» and «+» under the ruler: one mark (5 minutes) less or more with a
/// tap. Less on the start side and more on the end side, the way the
/// ruler's own numbers grow.
class SimplifiedSnoozeSteps extends StatelessWidget {
  const SimplifiedSnoozeSteps({
    super.key,
    required this.maxMinutes,
    required this.minutes,
    required this.onChanged,
  });

  final int maxMinutes;
  final int minutes;
  final ValueChanged<int> onChanged;

  static const int _step = snoozeStepMinutes;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      SimplifiedSnoozeStep(
        key: const Key('snooze-less'),
        icon: ActionIcons.minus,
        onPressed: minutes > _step ? () => onChanged(minutes - _step) : null,
      ),
      SimplifiedSnoozeStep(
        key: const Key('snooze-more'),
        icon: ActionIcons.plus,
        onPressed: minutes < maxMinutes
            ? () => onChanged(minutes + _step)
            : null,
      ),
    ],
  );
}

/// A round «−» or «+» beside the ruler: five minutes less or more with
/// one tap, for a hand that slides a ruler less easily. The ruler itself
/// is the one slider a screen reader meets, so this is not read again.
class SimplifiedSnoozeStep extends StatelessWidget {
  const SimplifiedSnoozeStep({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;

  /// Null at the ruler's end: nothing less, or nothing more, to choose.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 64,
      height: 64,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: SimplifiedColors.surface.withValues(alpha: .16),
          foregroundColor: SimplifiedColors.surface,
          disabledBackgroundColor: SimplifiedColors.surface.withValues(
            alpha: .06,
          ),
          disabledForegroundColor: SimplifiedColors.onDarkMuted,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: 30),
      ),
    ),
  );
}

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
