import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// A grouped information row with its value below the label on the RTL start.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.onEdit,
    this.editLabel,
    this.ltr = false,
  });

  final String label;
  final String value;
  final VoidCallback? onEdit;

  /// What a screen reader says for the pencil, for example "تعديل اسم العرض".
  final String? editLabel;

  /// The value is a number (the phone number) and is written left to right.
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  label,
                  textAlign: TextAlign.start,
                  style: text.bodySmall?.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  textAlign: ltr ? TextAlign.right : TextAlign.start,
                  textDirection: ltr ? TextDirection.ltr : null,
                  style: text.bodyLarge,
                ),
              ],
            ),
          ),
          if (onEdit != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Icon(
              AppIcons.pencil,
              size: AppSizes.iconSmall,
              color: context.tokens.textSecondary,
            ),
          ],
        ],
      ),
    );
    if (onEdit == null) return row;
    return Semantics(
      button: true,
      label: editLabel ?? label,
      value: value,
      excludeSemantics: true,
      onTap: onEdit,
      child: InkWell(onTap: onEdit, child: row),
    );
  }
}
