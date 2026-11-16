import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/components/task_button_role.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
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
