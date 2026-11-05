import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:flutter/material.dart';

/// A "nothing here yet" note for an empty section, with an optional action
/// such as opening the add sheet. Replaces each feature's own hand-rolled
/// empty-state layout with one consistent note style ([InsetText.note]).
class EmptyStateNote extends StatelessWidget {
  const EmptyStateNote(this.message, {super.key, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        InsetText.note(message),
        if (actionLabel != null && onAction != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.inset,
                  ),
                ),
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ),
          ),
      ],
    );
  }
}
