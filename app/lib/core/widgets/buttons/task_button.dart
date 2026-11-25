import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// One button under a task that is due, in the look of its [role]: its
/// icon, then its words, centred. [semanticLabel] replaces the words for a
/// screen reader when they alone would not say which task it answers.
class TaskButton extends StatelessWidget {
  const TaskButton({
    super.key,
    required this.role,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  final TaskButtonRole role;
  final IconData icon;
  final String label;

  /// Null shows the button as not pressable.
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final String? said = semanticLabel;
    final Widget words = Text(label, textAlign: TextAlign.center);
    final Widget button = OutlinedButton.icon(
      style: role.style,
      onPressed: onPressed,
      // The answer is a size up, its icon with it.
      icon: Icon(
        icon,
        size: role == TaskButtonRole.answer
            ? AppSizes.icon
            : AppSizes.iconSmall,
      ),
      // With its own label the words are not said twice; the button keeps
      // its role and its tap for the screen reader.
      label: said == null ? words : ExcludeSemantics(child: words),
    );
    if (said == null) return button;
    return MergeSemantics(
      child: Semantics(label: spoken(said), child: button),
    );
  }
}

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
