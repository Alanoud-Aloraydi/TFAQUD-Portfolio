import 'package:app/core/constants/app_icons.dart';
import 'package:app/features/medications/domain/snooze_limit.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snooze_step.dart';
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
        icon: AppIcons.minus,
        onPressed: minutes > _step ? () => onChanged(minutes - _step) : null,
      ),
      SimplifiedSnoozeStep(
        key: const Key('snooze-more'),
        icon: AppIcons.plus,
        onPressed: minutes < maxMinutes
            ? () => onChanged(minutes + _step)
            : null,
      ),
    ],
  );
}
