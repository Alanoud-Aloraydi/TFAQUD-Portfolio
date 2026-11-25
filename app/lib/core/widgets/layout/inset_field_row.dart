import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:flutter/material.dart';

/// A row that cannot be tapped, with the small label in its column and any
/// widget as its value, such as a name read from the account.
class InsetFieldRow extends StatelessWidget {
  const InsetFieldRow({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
  });

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.button),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: <Widget>[
              InsetRowLabel(label),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: child),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The look of a text field inside a form row: no border and no fill (the
/// card is its boundary), and a light [hint] while it is empty.
InputDecoration insetFieldDecoration(TextTheme text, String? hint) =>
    InputDecoration(
      hintText: hint,
      hintStyle: text.bodyMedium?.copyWith(
        color: AppSemanticColors.borderControlBase,
      ),
      filled: false,
      isDense: true,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    );
