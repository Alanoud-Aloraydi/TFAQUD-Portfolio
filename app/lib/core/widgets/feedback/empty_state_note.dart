import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// A "nothing here yet" note for an empty section, with an optional action
/// such as opening the add sheet. Replaces each feature's own hand-rolled
/// empty-state layout with one consistent note style.
///
/// The note and its button sit in the middle of the section, the way iOS
/// shows an empty view (the message, then the action under it, centred),
/// so every empty section of the app looks the same.
class EmptyStateNote extends StatelessWidget {
  const EmptyStateNote(
    this.message, {
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    // Full width (even inside a start-aligned column), only as tall as the
    // note, so the middle is the section's middle.
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.inset),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.tokens.textSecondary),
            ),
          ),
          if (actionLabel != null && onAction != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              // Filled, not a bare text link: a clear, tappable button.
              child: FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(AppIcons.plus, size: 18),
                label: Text(actionLabel!),
              ),
            ),
        ],
      ),
    );
  }
}
