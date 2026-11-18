import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// What an [EmptyStateNote] says: the message and, when there is one, the
/// button that acts on it. Where the note sits is the note's own business.
class EmptyStateNoteContent extends StatelessWidget {
  const EmptyStateNoteContent({
    super.key,
    required this.message,
    required this.fillsSection,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// True for a whole empty tab or section.
  final bool fillsSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.inset),
          child: Text(
            message,
            textAlign: TextAlign.center,
            // A whole empty tab has nothing else to read, so it speaks up;
            // a note under a list stays quiet.
            style:
                (fillsSection
                        ? Theme.of(context).textTheme.bodyLarge
                        : Theme.of(context).textTheme.bodySmall)
                    ?.copyWith(color: context.tokens.textSecondary),
          ),
        ),
        if (actionLabel != null && onAction != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            // Filled, not a bare text link: a clear, tappable button.
            child: FilledButton.tonalIcon(
              onPressed: onAction,
              icon: const Icon(ActionIcons.plus, size: 18),
              label: Text(actionLabel!),
            ),
          ),
      ],
    );
  }
}
