import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/medications/domain/entities/snooze_limit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';

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
