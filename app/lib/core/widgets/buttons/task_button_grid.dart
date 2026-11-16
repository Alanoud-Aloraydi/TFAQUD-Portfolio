import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// The buttons of a task: the [answer] it asks for across the whole width,
/// then the [choices] two to a line, each pair of one width and one height
/// (a pair grows together when its words wrap), with the small gap between
/// them both ways. A last lone choice takes its whole line.
class TaskButtonGrid extends StatelessWidget {
  const TaskButtonGrid({
    super.key,
    this.answer,
    this.choices = const <Widget>[],
  });

  /// The one button the task asks for, alone on the line above the rest so
  /// nothing shares the eye with it. Null where the answer has passed and
  /// only the choices are left.
  final Widget? answer;

  /// «ذكّرني لاحقًا», «تخطي», «إلغاء»: everything that is not the answer.
  final List<Widget> choices;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      ?answer,
      for (int first = 0; first < choices.length; first += 2) ...<Widget>[
        if (first > 0 || answer != null) const SizedBox(height: AppSpacing.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: choices[first]),
              if (first + 1 < choices.length) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: choices[first + 1]),
              ],
            ],
          ),
        ),
      ],
    ],
  );
}
