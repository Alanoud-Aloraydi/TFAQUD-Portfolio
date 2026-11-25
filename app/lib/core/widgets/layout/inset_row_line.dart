import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:flutter/material.dart';

/// The padded line of an [InsetRow], at least a button high: its [content],
/// then an optional [trailing] control and an optional chevron.
class InsetRowLine extends StatelessWidget {
  const InsetRowLine({
    super.key,
    required this.content,
    this.trailing,
    this.showChevron = false,
  });

  final List<Widget> content;
  final Widget? trailing;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: <Widget>[
            ...content,
            if (trailing != null) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
            if (showChevron) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              // The forward chevron (SF chevron.forward) mirrors in Arabic: it points to the
              // end (left), where the row leads.
              const Icon(
                ArrowIcons.forward,
                size: AppSizes.iconSmall,
                color: AppSemanticColors.borderControlBase,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What an [InsetRow] shows before its trailing parts, by kind of row.
extension InsetRowContent on InsetRow {
  /// The label alone; or the icon and the label of an action row; or the
  /// small label, then the value or its placeholder, of a field row.
  List<Widget> content(TextTheme text) {
    final String? shown = value ?? placeholder;
    return labelOnly
        ? <Widget>[Expanded(child: Text(label, style: text.bodyLarge))]
        : leading != null
        ? <Widget>[
            IconTheme.merge(
              data: IconThemeData(
                color: labelColor ?? AppSemanticColors.textPrimary,
                size: AppSizes.iconSmall,
              ),
              child: leading!,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: text.bodyLarge?.copyWith(color: labelColor),
              ),
            ),
          ]
        : <Widget>[
            InsetRowLabel(label),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: shown == null
                  ? const SizedBox.shrink()
                  : Text(
                      shown,
                      style: value == null
                          ? text.bodyMedium?.copyWith(
                              color: AppSemanticColors.borderControlBase,
                            )
                          : text.bodyLarge,
                    ),
            ),
          ];
  }
}
