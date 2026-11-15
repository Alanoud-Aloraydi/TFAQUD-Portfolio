import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The buttons of a task two to a line, each pair of one width and one
/// height (a pair grows together when its words wrap), with the small gap
/// between them both ways. A last lone button takes its whole line.
class TaskButtonGrid extends StatelessWidget {
  const TaskButtonGrid({super.key, required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (int first = 0; first < buttons.length; first += 2) ...<Widget>[
        if (first > 0) const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: buttons[first]),
              if (first + 1 < buttons.length) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: buttons[first + 1]),
              ],
            ],
          ),
        ),
      ],
    ],
  );
}
